# EUDI Verifier Endpoint (dentsusoken fork)

This is a fork of [eudi-srv-verifier-endpoint](https://github.com/eu-digital-identity-wallet/eudi-srv-verifier-endpoint).

For full documentation, see the [original README](https://github.com/eu-digital-identity-wallet/eudi-srv-verifier-endpoint/blob/main/README.md).

## How this project was created

Run from the vecrea-id repository root. Create the dentsusoken fork on GitHub first.

```bash
cd vecrea-id
git submodule add https://github.com/dentsusoken/eudi-srv-verifier-endpoint projects/eudi-srv-verifier-endpoint
cd projects/eudi-srv-verifier-endpoint
git remote add upstream https://github.com/eu-digital-identity-wallet/eudi-srv-verifier-endpoint
git fetch upstream
git checkout main
git reset --hard upstream/main
git push -u origin main --force
```

Note: Add the submodule from the dentsusoken fork URL so `.gitmodules` points to the fork from the start. The submodule references commits (e.g. this UPDATE.md) that exist only in our fork, not in the original. GitHub uses the `.gitmodules` URL to build the submodule link, so it must point to the fork. The fork is now [public](https://github.com/dentsusoken/eudi-srv-verifier-endpoint), so the link works for everyone.

## Remote configuration

| Remote   | URL                                                       |
|----------|-----------------------------------------------------------|
| origin   | https://github.com/dentsusoken/eudi-srv-verifier-endpoint |
| upstream | https://github.com/eu-digital-identity-wallet/eudi-srv-verifier-endpoint |

### Initial setup (first-time clone)

Because `.gitmodules` points to the dentsusoken fork, cloning gives you `origin` = fork. Add `upstream` before using the branch workflow:

```bash
cd projects/eudi-srv-verifier-endpoint
git remote add upstream https://github.com/eu-digital-identity-wallet/eudi-srv-verifier-endpoint
```

## Working with branches

### Creating a new branch

```bash
cd projects/eudi-srv-verifier-endpoint
git fetch upstream
git checkout -b <branch-name> upstream/main
```

### Updating main from upstream

To sync `main` with the original repository:

```bash
cd projects/eudi-srv-verifier-endpoint
git checkout main
git fetch upstream
git rebase upstream/main
```

### Updating a branch (other than main) from upstream

To sync a branch with the latest upstream:

```bash
cd projects/eudi-srv-verifier-endpoint
git checkout <branch-name>
git fetch upstream
git rebase upstream/main
```
