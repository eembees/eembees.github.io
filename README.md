# MagBlog

Magnus' hugo blog. 

## Commands that are useful here 

Making `.meta` files for image files in galleries. 

```zsh
for file in *.jpg *.jpeg; do [[ ! -f "$file.meta" ]] && echo '{"Title":""}' > "$file.meta"; done
```
