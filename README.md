git commit -m "Clean up dotfiles-omarchy and sync local state"

git add .
git commit -m "Add essential configuration files"

git push -u origin master

git pull --rebase origin master
git push origin master
