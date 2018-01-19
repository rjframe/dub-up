# DUB-Up

Automated dependency management for D, inspired by [pyup-bot](https://pyup.io/).

DUB-Up will be two tools, a command-line and Github app, that will search for
dependency updates and make a PR against your repository, providing links to the
project's DUB page, home page, and changelog if present.

Advantages:

* No need to schedule manual updates.
* Relevant information comes to you; no searching for release notes, etc.
* Your CI will build the PR - you know whether a dependency upgrade will
  break your build.
