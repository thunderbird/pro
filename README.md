# Welcome to Thunderbird Pro!

Thunderbird Pro is a subscription-based suite of three open source services that extend the Thunderbird ecosystem:

| Service | What it does | Primary repo |
| --- | --- | --- |
| Thundermail | Modern, privacy‑first email hosting (built on Stalwart) | https://github.com/stalwartlabs/stalwart |
| Appointment | Shareable scheduling links that write to a user’s calendar without exposing the whole calendar | https://github.com/thunderbird/appointment |
| Thunderbird Send | End‑to‑end encrypted file sharing with a web UI and a Thunderbird add‑on | https://github.com/thunderbird/tbpro-add-on |

Each service is open source and can be deployed on its own and run independently. However when combined, they all read the same user profile from a shared authentication database that makes them feel like a single product.

## Getting Started - Contributing

### 1. Fork & clone the repo
Regardless of which repo you plan to contribute to, general ettiquette for contribution is to fork the repository to your own GitHub namespace and then clone your fork. [Read about this process on docs.github.com.](https://docs.github.com/en/get-started/exploring-projects-on-github/contributing-to-a-project)

### 2. Review the project documentation

| Service | Documentation |
| --- | --- |
| Thundermail | [project README.md](https://github.com/thunderbird/mailstrom/blob/main/README.md) |
| Appointment | [project README.md](https://github.com/thunderbird/appointment/blob/main/README.md) |
| Thunderbird Send | [project README.md](https://github.com/thunderbird/tbpro-add-on/blob/main/README.md) |

### 3. Open a PR

1. Create a branch: `git checkout -b my‑feature`
2. Make your changes and build/run the service locally (`cargo build && cargo run`, `npm run build`, etc.).
3. Commit your changes ([Read about writing good commit messages](https://www.gitkraken.com/learn/git/best-practices/git-commit-message)
4. Push and open a Pull Request against the upstream repository ([Read about opening a PR from a fork](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request-from-a-fork)).

### 4. Review & merge
At least one maintainer must approve the pull request before the change is merged. Often additional changes are requested and can be made in the same PR by updating your feature branch on your fork. Once all changes and comments have been adressed and approved, the PR is ready to be merged into the main project.

## Need Help? Found a bug? Have an idea? Want to chat?
If any of these apps are not behaving like it should, or you are not sure if you've encountered a bug:
* Ask a question on our Matrix channel: [#thunderbird-pro-early-birds:mozilla.org](https://matrix.to/#/#tb-pro-early-birds:mozilla.org)

If you are certain you've identified a bug in an app and would like to help fix it:
* Open an issue in the relevant repo; include important information like OS, version, and steps to reproduce.
| Service | Issue Tracker |
| --- | --- |
| Thundermail | https://github.com/thunderbird/mailstrom/issues |
| Appointment | https://github.com/thunderbird/appointment/issues |
| Thunderbird Send | https://github.com/thunderbird/tbpro-add-on/issues |

If you have an idea how to improve one of these services:
* Tell us about and vote on your feature ideas on [ideas.tb.pro](https://ideas.tb.pro/)

The Thunderbird Community uses Matrix to communicate:
* General chat and support for Thunderbird Pro services: [#thunderbird-pro-early-birds:mozilla.org](https://matrix.to/#/#tb-pro-early-birds:mozilla.org)
* Reach the broader Thunderbird Community in the [#thunderbird-community:mozilla.org](https://matrix.to/#/#thunderbird-community:mozilla.org)

## Roadmap
To learn more about all the wonderful things planned for this year please see our [roadmap](https://roadmaps.thunderbird.net/en-US/services/).
