# +++ Repo Operator +++

![logo](./docs/logo.webp)
`repo-operator` is a modular and extensible repository management tool that streamlines development workflows by providing reusable, Docker-based, hermetic Makefile targets for common tasks. This ensures that all builds, tests, and operations are fully isolated and reproducible, regardless of the local environment. The project can be added as a Git submodule and used to manage operations like building, testing, and generating documentation across multiple repositories.

Documentation can be found at [ioaiaaii.github.io/project/cloud-repo-operator](https://ioaiaaii.github.io/project/cloud-repo-operator/)!

## Features

- **Modular Structure**: Reuse and include Makefile targets across projects.
- **Hermetic Targets**: All operations are executed within Docker containers, ensuring reproducibility and isolation from the host environment.
- **Customizable**: Allows the overwriting of key variables to suit the specific project needs.
- **Dyanamic Targets**: Supports dynamic Makefile targets that allow you to customize the behavior of commands by passing variables at runtime, to reuse the same target for different operations, such as building Docker images or running specific tasks, without hardcoding values for each case. Imaging a remote function as interface with params!

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
