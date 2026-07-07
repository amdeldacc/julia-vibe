using Lux, OrdinaryDiffEq, Optimisers, Random, Plots, Statistics, Zygote

const g::Float64 = 9.81

# ═══════════════════════════════════════════════
# 1. Data Generation
# ═══════════════════════════════════════════════

function pendulum_ode!(du, u, p, t)
    θ, ω = u; L = p[1]
    du[1] = ω; du[2] = -g/L * sin(θ)
end

function generate_trajectory(θ₀, ω₀, L; tspan=(0.0, 10.0), dt=0.05, nT=200)
    save_pts = range(tspan[1], tspan[2]; length=nT+1)[1:end-1]
    sol = solve(ODEProblem(pendulum_ode!, [θ₀, ω₀], tspan, [L]), Tsit5(), saveat=save_pts)
    return Float32.(hcat(sol.u...))
end

function generate_dataset(N; L_range=(0.5, 2.0), θ_range=(-π, π), ω_range=(-5.0, 5.0),
                         tspan=(0.0, 10.0), dt=0.05, rng=Random.GLOBAL_RNG)
    nT = Int(tspan[2] / dt)
    data = zeros(Float32, 2, nT, N)
    for i in 1:N
        θ₀ = rand(rng) * (θ_range[2] - θ_range[1]) + θ_range[1]
        ω₀ = rand(rng) * (ω_range[2] - ω_range[1]) + ω_range[1]
        L = rand(rng) * (L_range[2] - L_range[1]) + L_range[1]
        data[:, :, i] = generate_trajectory(θ₀, ω₀, L; tspan, dt, nT)
    end
    return data
end

function make_windows(data, ctx, k=3)
    nF, nT, nTr = size(data)
    ns = nTr * (nT - ctx - k + 1)
    xs = zeros(Float32, nF, ctx, ns)
    ys = zeros(Float32, nF, k, ns)
    idx = 0
    for t in 1:nTr, i in 1:(nT - ctx - k + 1)
        idx += 1
        xs[:, :, idx] = data[:, i:i+ctx-1, t]
        ys[:, :, idx] = data[:, i+ctx:i+ctx+k-1, t]
    end
    return xs, ys
end

# ═══════════════════════════════════════════════
# 2. Positional Encoding
# ═══════════════════════════════════════════════

function make_pe(d, s)
    pe = zeros(Float32, d, s, 1)
    for p in 0:s-1, i in 0:2:d-1
        a = p / Float32(10000)^(i / d)
        pe[i+1, p+1, 1] = sin(a)
        i+2 <= d && (pe[i+2, p+1, 1] = cos(a))
    end
    return pe
end

struct AddConst{T} <: Lux.AbstractLuxLayer
    c::T
end
(l::AddConst)(x, ps, st) = (x .+ l.c, st)
Lux.initialparameters(::AbstractRNG, ::AddConst) = NamedTuple()
Lux.initialstates(::AbstractRNG, ::AddConst) = NamedTuple()

# ═══════════════════════════════════════════════
# 3. Encoder Block
# ═══════════════════════════════════════════════

function encoder_block(d::Int, h::Int, ff::Int)
    Lux.@compact(
        attn = MultiHeadAttention(d; nheads=h, attention_dropout_probability=0.0f0),
        ln1 = LayerNorm(d),
        ln2 = LayerNorm(d),
        ff1 = Lux.Dense(d => ff),
        ff2 = Lux.Dense(ff => d),
    ) do x
        s = size(x)
        attn_out = attn(x)
        x = reshape(ln1(reshape(x .+ attn_out[1], s[1], :)), s)
        x = reshape(ln2(reshape(x .+ ff2(Lux.relu(ff1(x))), s[1], :)), s)
        @return x
    end
end

# ═══════════════════════════════════════════════
# 4. Build Model
# ═══════════════════════════════════════════════

function build_model(; d=32, h=4, n=2, ff=128, ctx=20)
    layers = [Lux.Dense(2 => d), AddConst(make_pe(d, ctx))]
    for _ in 1:n
        push!(layers, encoder_block(d, h, ff))
    end
    push!(layers, Lux.Dense(d => 2))
    return Lux.Chain(layers)
end

# ═══════════════════════════════════════════════
# 5. Training
# ═══════════════════════════════════════════════

function shift_cx(cx, pred)
    nF, ctx, B = size(cx)
    cat(cx[:, 2:end, :], reshape(pred, nF, 1, B); dims=2)
end

function multi_step_loss_k3(model, cx, yb, p, st)
    nF, ctx, B = size(cx)
    # explicit 3-step unroll — no loops, Zygote-safe
    yp1, _ = model(cx, p, st)
    p1 = yp1[:, end, :]
    l = mean((p1 .- yb[:, 1, :]) .^ 2) / 3
    cx2 = shift_cx(cx, p1)
    yp2, _ = model(cx2, p, st)
    p2 = yp2[:, end, :]
    l += mean((p2 .- yb[:, 2, :]) .^ 2) / 3
    cx3 = shift_cx(cx2, p2)
    yp3, _ = model(cx3, p, st)
    p3 = yp3[:, end, :]
    l += mean((p3 .- yb[:, 3, :]) .^ 2) / 3
    return l
end

function train!(model, xs, ys; epochs=50, bs=128, lr=0.001f0, noise=0.05f0,
                ss_p0=0.3f0, ss_steps=3, k=3, rng=Random.GLOBAL_RNG)
    ps, st = Lux.setup(rng, model)
    opt = Optimisers.setup(Optimisers.Adam(lr), ps)
    n = size(xs, 3)
    losses = Float32[]

    for ep in 1:epochs
        p_ss = ss_p0 * (1.0f0 - (ep - 1) / epochs)

        perm = randperm(rng, n)
        el = 0.0f0
        nb = 0
        for s in 1:bs:n
            stop = min(s + bs - 1, n)
            idx = perm[s:stop]
            xb = xs[:, :, idx]  # (2, ctx, B)
            yb = ys[:, :, idx]  # (2, k, B)

            # scheduled sampling: corrupt context with own preds (no grad)
            if rand(rng) < p_ss
                cx = xb
                for _ in 1:ss_steps
                    yp_, _ = model(cx, ps, st)
                    pred = yp_[:, end, :]
                    cx = cat(cx[:, 2:end, :], reshape(pred, 2, 1, length(idx)); dims=2)
                end
                xb_ss = cx
            else
                xb_ss = xb
            end

            # noise
            xb_in = xb_ss + noise * randn(rng, Float32, size(xb_ss))

            # multi-step loss with gradient
            gs = Zygote.gradient(ps) do p
                multi_step_loss_k3(model, xb_in, yb, p, st)
            end[1]

            opt, ps = Optimisers.update(opt, ps, gs)

            # eval loss on clean inputs for logging
            yp_, _ = model(xb, ps, st)
            el += mean((yp_[:, end, :] .- yb[:, 1, :]) .^ 2)
            nb += 1
        end
        push!(losses, el / nb)
        (ep % 10 == 0 || ep == 1) && println("Epoch $ep/$(epochs) — loss: $(round(losses[end], sigdigits=4))")
    end
    return ps, st, losses
end

# ═══════════════════════════════════════════════
# 6. Autoregressive Rollout
# ═══════════════════════════════════════════════

function rollout(model, ps, st, θ₀, ω₀, L; n_steps=200, dt=0.05, ctx=20)
    # Warmup context from solver
    tw = (ctx - 1) * dt
    sol = solve(ODEProblem(pendulum_ode!, [θ₀, ω₀], (0.0, tw), [L]), Tsit5(), saveat=dt)
    cx = Float32.(hcat(sol.u...))
    preds = zeros(Float32, 2, n_steps + 1)
    preds[:, 1] = cx[:, end]  # seed = last warmup state

    for i in 1:n_steps
        xb = reshape(cx, (2, ctx, 1))
        yp, _ = model(xb, ps, st)
        ns = Float32.(yp[:, end, 1])
        preds[:, i+1] = ns
        cx = hcat(cx[:, 2:end], ns)
    end

    tt = (ctx + n_steps) * dt
    sol = solve(ODEProblem(pendulum_ode!, [θ₀, ω₀], (0.0, tt), [L]), Tsit5(), saveat=dt)
    true_st = Float32.(hcat(sol.u...))[:, ctx+1:end]
    return preds, true_st, collect(sol.t[ctx+1:end])
end

# ═══════════════════════════════════════════════
# 7. Main
# ═══════════════════════════════════════════════

function main()
    rng = Random.MersenneTwister(42)
    ctx = 20; k = 3

    println("Generating data...")
    data = generate_dataset(500; L_range=(0.5, 3.0), θ_range=(-π, π), ω_range=(-8.0, 8.0), rng=rng)
    println("  Data: $(size(data))")

    xs, ys = make_windows(data, ctx, k)
    println("  Windows: $(size(xs)) -> $(size(ys))")

    model = build_model(d=24, h=3, n=2, ff=96, ctx=ctx)
    nparams = Lux.parameterlength(Lux.setup(rng, model)[1])
    println("  Model parameters: $nparams")

    println("Training...")
    @time ps, st, losses = train!(model, xs, ys; epochs=50, bs=128, noise=0.05f0, k, rng)

    gr()
    plot(losses, xlabel="Epoch", ylabel="MSE", title="Training Loss", lw=2, legend=false)
    savefig("training_loss.png")
    println("Loss: $(losses[end])")

    println("\nEvaluation:")
    tests = [(0.0, 2.0, 1.2), (1.5, -1.0, 0.8), (-2.0, 1.5, 1.5), (2.8, -2.5, 0.6), (-1.0, 0.5, 1.0)]
    p = plot(layout=(5, 3), size=(1200, 1000), legend=:topright)
    for (i, (θ₀, ω₀, L)) in enumerate(tests)
        pred_tr, true_tr, tv = rollout(model, ps, st, θ₀, ω₀, L; ctx)
        eθ, eω = abs.(pred_tr[1,:] .- true_tr[1,:]), abs.(pred_tr[2,:] .- true_tr[2,:])
        println("  Test $i: MSE_θ=$(round(mean(eθ.^2), sigdigits=4)), MSE_ω=$(round(mean(eω.^2), sigdigits=4))")

        plot!(p[i,1], tv, true_tr[1,:], label="True θ", lw=1.5, c=:blue)
        plot!(p[i,1], tv, pred_tr[1,:], label="Surr θ", lw=1.5, ls=:dash, c=:red)
        plot!(p[i,2], tv, true_tr[2,:], label="True ω", lw=1.5, c=:blue)
        plot!(p[i,2], tv, pred_tr[2,:], label="Surr ω", lw=1.5, ls=:dash, c=:red)
        plot!(p[i,3], tv, eθ, label="|Δθ|", lw=1.5, c=:orange)
        plot!(p[i,3], tv, eω, label="|Δω|", lw=1.5, c=:purple)
    end
    savefig("surrogate_evaluation.png")
    println("Saved surrogate_evaluation.png")
end

main()
