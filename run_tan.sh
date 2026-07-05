#!/bin/bash
export DISPLAY=:0
export GKS_ENCODING=utf8
export GKSwstype=100
cd /home/piou/vibe-julia
julia plot_tan.jl
