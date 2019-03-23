#!/bin/zsh
git commit -am "update"
git push
hexo clean
hexo g
hexo d
