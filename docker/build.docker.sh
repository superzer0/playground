full_path=$(realpath $0)
script_path=$(dirname $full_path)
docker_file_path="$script_path/debug-image.docker"
echo "Using $docker_file_path docker file"
docker build -f $docker_file_path -t superzer0/debug-container:latest $docker_file_path
docker push superzer0/debug-container:latest
