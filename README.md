# Welcome to Thunderbird Pro!

Thunderbird Pro is a subscription-based suite of three open source services that extend the Thunderbird ecosystem:

| Service | What it does | Primary repo |
| --- | --- |
| Thundermail | Modern, privacy‑first email hosting (built on Stalwart) | https://github.com/stalwartlabs/stalwart |
| Appointment | Shareable scheduling links that write to a user’s calendar without exposing the whole calendar | ttps://github.com/thunderbird/appointment |
| Thunderbird Send | End‑to‑end encrypted file sharing (up to 20 GB) with a web UI and a Thunderbird add‑on | https://github.com/thunderbird/tbpro-add-on |

Each service is open source and can be deployed on its own and run independently. However when combined, they all read the same user profile from a shared authentication database that makes them feel like a single product.

## Getting Started - Contributing

### 1. Fork & clone the repo
Regardless of which repo you plan to contribute to, general ettiquette for contribution is to fork the repository to your own GitHub namespace and then clone your fork. [Read about this process on docs.github.com.](https://docs.github.com/en/get-started/exploring-projects-on-github/contributing-to-a-project)

### 2. Install the development dependencies

| Service | Commands |
| --- | --- |
| Thundermail (rust) | `rustup toolchain install stable && cargo build` |
| Appointment (Node / TypeScript) | `npm ci && npm run build` |
| Thunderbird Send (Web + Add‑on) | `npm ci && npm run dev` (frontend)<br>`web-ext lint && web-ext build` (add‑on) |

Each repo contain a `CONTRIBUTING.md` that lists the exact versions used. Copy those into your environment.

### 3. Run the service locally

| Service | Commands |
| --- | --- |
| Thundermail | `cargo run --release -- --config ./config/dev.toml` |
| Appointment | `npm start`<br>This will start a local server on `localhost:3000`. |
| Thunderbird Send | `npm run dev`<br>This will start the web UI on `localhost:8080`. |

### 4. Open a PR

1. Create a branch: `git checkout -b my‑feature`
2. Make your changes and build/run the service locally (`cargo build && cargo run`, `npm run build`, etc.).
3. Commit your changes ([Read about writing good commit messages](https://www.gitkraken.com/learn/git/best-practices/git-commit-message)
4. Push and open a Pull Request against the upstream repository ([Read about opening a PR from a fork](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request-from-a-fork)).

### 5. Review & merge
At least one maintainer must approve the pull request before the change is merged. Often additional changes are requested and can be made in the same PR by updating your feature branch on your fork. Once all changes and comments have been adressed and approved, the PR is ready to be merged into the main project.

## Where to ask questions
* Matrix channel - [#thunderbird-pro-early-birds:mozilla.org](https://matrix.to/#/#tb-pro-early-birds:mozilla.org)
* Bug reports - open an issue in the relevant repo; include important information like OS, version, and steps to reproduce.
