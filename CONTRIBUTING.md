# Contributing to the Individual CMFs Toolbox

Welcome! We appreciate your interest in contributing to the MATLAB Individual Cone Fundamentals Toolbox. This project aims to provide a highly accurate, numerically stable, and strictly verifiable implementation of modern colorimetry standards.

To maintain the scientific integrity and reproducibility of the codebase, we ask that all contributors follow the guidelines outlined below.

## 1. Getting Started

1. **Fork and Clone:** Fork the repository to your own GitHub account and clone it locally.
2. **MATLAB Version:** Ensure you are using **MATLAB R2023b** or newer.
3. **Setup:** Open the `individual-cmfs-matlab.prj` file in MATLAB to automatically configure the project paths.
4. **Branching:** Create a new branch for your feature or bug fix, for example `feature/new-lens-model` or `fix/normalization-cache`.

## 2. Code Style and Architecture

This toolbox relies on modern MATLAB conventions to ensure robustness and clarity. When writing new code, please adhere to the following standards:

- **Arguments Blocks:** Use `arguments` blocks for input validation in all public-facing methods, with the most specific validator that fits. Prefer the ones MATLAB ships, for example `mustBeMember`, `mustBeNonnegative` or `mustBeInRange`, over writing a new one; `toolbox/+validators/` holds only the three checks MATLAB has no equivalent for. Where a value means "not supplied", use `[]` rather than `NaN`.
- **Value Classes vs. Handle Classes:** Understand the distinction within the project. The `ObserverParameters` class is deliberately a value object to capture decoupled snapshots, while `IndividualCMF` is a handle class.
- **Strict Layering:** Respect the leaf-to-root dependency graph. Pure-function compute stages reside exclusively in the `+pipeline/` namespace and must never reference `IndividualCMF` or observer state directly.
- **Single Source of Truth:** Never hardcode physiological constants. Always reference `CIE170.m` for shared values or the specific template class for model-specific constants.

For a comprehensive breakdown of the class hierarchy, pipeline stages, and extension points, thoroughly review [`ARCHITECTURE.md`](ARCHITECTURE.md) before beginning development.

## 3. Testing and CI/CD

Testability and reproducibility are paramount. We use MATLAB's built-in `buildtool` to manage static analysis and unit testing. **All tests must pass locally before submitting a pull request.**

From the repository root, run the default pipeline:

```matlab
buildtool
```

This executes the two default tasks:

1. **`buildtool check`:** Runs static analysis (`codeIssues`) on the `toolbox/` directory. Your build will fail if any warning- or error-severity issues are detected.
2. **`buildtool test`:** Runs the full unit and integration test suite, emitting JUnit XML and Cobertura coverage reports.

Three further tasks exist and are not part of the default run. `buildtool clean` removes the generated reports.

1. **`buildtool doc`:** Regenerates the Help Browser reference from the class help comments. It runs the worked examples so their figures appear, so it takes a few minutes.
2. **`buildtool package`:** Builds the redistributable `.mltbx`. It depends on `check`, `test` and `doc`, so a packaged toolbox always ships documentation matching its code.

The reference documentation is generated, not written. If you edit a help comment on a public class or method, you are editing the published page; run `buildtool doc` and read it back if the change is substantial.

### Parity Testing

If you modify anything within the `+pipeline/`, `NormalizationCache`, or `PhotopigmentTemplate` hierarchies, you must ensure that machine-precision parity with the reference Python implementation, `pycone`, is maintained.

The parity harness is located in `tests/parity/`. Please review `tests/parity/README.md` for instructions on running the cross-language comparisons.

## 4. Submitting a Pull Request and CLA

Once your feature or fix is complete and all `buildtool` tasks pass:

1. Push your branch to your forked repository.
2. Open a pull request against the `main` branch of `sfu-cs-vision-lab/individual-cmfs-matlab`.
3. In your pull request description, please include:
   - A clear summary of the changes and the rationale behind them.
   - References to any relevant academic literature if you are introducing a new physiological model or constant.
   - Confirmation that `buildtool` runs cleanly.

### Contributor License Agreement

Before we can merge your contributions, you must sign a Contributor License Agreement, or CLA. This protects the project's academic open-source status, the contributors, and the downstream users.

We manage this automatically using **CLA Assistant**. When you open your first pull request, the CLA Assistant bot will leave a comment on your pull request prompting you to review and sign the agreement. You only need to do this once.

Once signed, the pull request status check will turn green, and we can proceed with the review.

## 5. Adding New Models

We welcome implementations of published alternative models. If you are adding a new photopigment, lens, or macular template:

1. Subclass the appropriate abstract base class, `PhotopigmentTemplate`, `LensTemplate`, or `MacularTemplate`. Implement its abstract methods and declare the abstract Constant properties, including `ValidRange` and `Domain`, which bound where the model may be evaluated.
2. Add the corresponding enumeration value in `toolbox/+enums/`.
3. Add one line to the base class's `REGISTRY`, mapping that enumeration member name to a constructor. Templates resolve through the registry, so nothing in `IndividualCMF` changes.
4. Add comprehensive unit tests isolating and covering the new template's spectral output and density calculations. `TemplateRegistryTest` already checks that the registry keys and the enumeration members agree in both directions, so adding the enumeration value without the registry line fails there rather than at runtime.
5. Register the new files in the MATLAB project, either from the Project Issues panel or with `addFile`. `ProjectRegistryTest` fails if a tracked file is missing from it.

Thank you for helping improve the scientific tooling for the color and vision research community.
