#!/bin/bash

json_path="/Users/$(whoami)/Library/Application Support/minecraft/launcher_profiles.json"
old_display_name="eriddoch"

echo "Enter your first name (lowercase): "
read display_name
echo $(sed 's/'"$old_display_name"'/'"$display_name"'/' "$json_path") > "$json_path"
