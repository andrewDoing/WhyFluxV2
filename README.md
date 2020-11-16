# Flux v2 and the GitOps Toolkit

## [Flux v2](https://github.com/fluxcd/flux2)

- Supports the same workflows as Flux v1, with more flexibility and using Kubernetes-native components.
- Existing Flux and Flux/Helm users are supported and migration is well supported.
- [Get Started With Flux v2 Tutorial](https://toolkit.fluxcd.io/get-started/), the following is required:
  - 2 Kubernetes clusters (staging and prod)
  - Github Username and public access token (PAT)
  - A bash terminal

- [Flux v1 to v2 Migration Guide](https://toolkit.fluxcd.io/guides/flux-v1-migration/)
- [FAQ on Flux v2](https://github.com/fluxcd/flux2/blob/main/docs/faq/index.md), including key differences from v1.
- [Flux v2 Roadmap](https://toolkit.fluxcd.io/roadmap/)
- [Migrate from the Helm Operator to the Helm Controller](https://toolkit.fluxcd.io/guides/helm-operator-migration/)

## [GitOps Toolkit (GOTK)](https://github.com/fluxcd/flux2#gitops-toolkit)

![overview](img/gitops-toolkit.png)

- GOTK is a set of composable APIs and specialized tools that can be used to build a CI/CD platform on top of Kubernetes.
- Users can make their own workflows using the components.
- Third parties can extend GOTK with new components.
