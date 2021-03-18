# Docker Makepkg
This Docker container can be used to build automated AUR Packages. This Docker container is used by OblivionOS to build the AUR Packages. This can´t 
be build directly on Dockerhub because of some security measures Dockerhub takes. This Docker container is optimized for use with Drone CI.
# Configuration
Configuration is done by environment variables
## Environment Variables
- DRONE_STEP_NAME: This is been used to define package name - OUTPUT_DIR: This is been used to define the output dir
# Contribution
Just go ahead and create an Issue or a Pull Request
