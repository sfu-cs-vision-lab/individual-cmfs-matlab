%[text] # Getting Started
%[text] The **Individual Cone Fundamentals Toolbox** computes observer-specific LMS cone spectral sensitivities, and quantities derived from them (RGB color matching functions, CIE XYZ, photopic luminance $V^*(\\lambda)$, chromaticity), from biophysical parameters: opsin genotype, age, retinal field size, and lens / macular / photopigment optical densities.
%[text] The defaults reproduce the CIE 170-1:2006 physiological standard observers -- via the Stockman & Rider (2023) analytic model of them, which tracks the published tables to about 0.02 in peak-normalized units rather than matching them digit for digit ([Example 01](matlab:open('Example01_Basics.m')) quantifies this). Every input can be overridden individually to model a specific observer or to study one biophysical parameter in isolation.
%[text] This guide is a one-minute orientation and a map of the worked examples. Run the cell below, then open whichever example matches what you want to do.
%[text] These files are plain-text Live Scripts. In R2025a and later the prose renders as formatted text; in earlier releases you see the `%[text]` markers as comments, and every file still runs correctly as an ordinary script.
%%
%[text] ## A first observer
%[text] `IndividualCMF` with no arguments returns the CIE 2006 10 deg standard observer. Evaluate any cone with `obs.L(wl)` / `obs.M(wl)` / `obs.S(wl)`, or all three with `obs.LMS(wl)`, passing wavelengths as a column vector.
obs = IndividualCMF();
obs.LMS((450:50:650)')
%[text] The `plotLMS` wrapper draws the same three fundamentals. It plots whatever the observer's output settings produce, so the curves are peak-normalized here only because `NormalizeOutput` defaults to true -- see [Example 09](matlab:open('Example09_OutputFormats.m')).
obs.plotLMS(Title="CIE 2006 10 deg cone fundamentals");
xlim([380 780]); ylim([0 1.05])
%%
%[text] ## Example gallery
%[text] The toolbox ships 19 worked examples (plain-text Live Scripts), roughly ordered from foundations to advanced usage. Click an example to open it.
%[text:table]
%[text] | # | Example | What it covers |
%[text] | --- | --- | --- |
%[text] | 01 | [The Basics](matlab:open('Example01_Basics.m')) | Construct an observer, evaluate cones, plot, normalization |
%[text] | 02 | [Standard Observers](matlab:open('Example02_StandardObservers.m')) | CIE 2006 2 deg and 10 deg observers; XYZ color matching functions |
%[text] | 03 | [How an Observer Is Assembled](matlab:open('Example03_HowAnObserverIsAssembled.m')) | The three components, shape vs magnitude, and what `CIE170` actually selects |
%[text] | 04 | [Field Size Effects](matlab:open('Example04_FieldSizeEffects.m')) | Macular pigment and photopigment OD vs field size |
%[text] | 05 | [Aging Effects](matlab:open('Example05_AgingEffects.m')) | Lens yellowing and the `LensModel` choice |
%[text] | 06 | [Genetic Variants](matlab:open('Example06_GeneticVariants.m')) | Ser180Ala polymorphism, hybrid cones, `Genotype` |
%[text] | 07 | [Photopigment Models](matlab:open('Example07_PhotopigmentModels.m')) | Stockman-Rider 2023 vs Govardovskii 2000 templates |
%[text] | 08 | [Computational Pipeline](matlab:open('Example08_ComputationalPipeline.m')) | The four-stage pipeline via the public API |
%[text] | 09 | [Output Formats](matlab:open('Example09_OutputFormats.m')) | `energy` / `quantal` / `absorptance` / `absorbance`, `LogOutput` |
%[text] | 10 | [RGB Color Matching](matlab:open('Example10_RGBColorMatching.m')) | RGB CMFs, negative lobes, custom display primaries |
%[text] | 11 | [Chromaticity Diagrams](matlab:open('Example11_ChromaticityDiagrams.m')) | lm and CIE xy chromaticity, spectral locus |
%[text] | 12 | [Photopic Luminance](matlab:open('Example12_Luminance.m')) | $V^*(\\lambda)$ and MacLeod-Boynton coordinates |
%[text] | 13 | [Observer Comparison](matlab:open('Example13_ObserverComparison.m')) | `compareTo`, RMS metrics, multi-observer overlays |
%[text] | 14 | [Dichromacy](matlab:open('Example14_Dichromacy.m')) | Protan / deutan / tritan via zero optical density |
%[text] | 15 | [Advanced Customization](matlab:open('Example15_AdvancedCustomization.m')) | Every parameter; `getParameters` round-trip |
%[text] | 16 | [Data Export](matlab:open('Example16_DataExport.m')) | `evaluate`, CSV and MAT export |
%[text] | 17 | [Normalization Methods](matlab:open('Example17_NormalizationMethods.m')) | Continuous vs Sampled peak normalization |
%[text] | 18 | [Publication Figures](matlab:open('Example18_PublicationFigures.m')) | Multi-panel composites; vector export |
%[text] | 19 | [Observer Metamerism](matlab:open('Example19_ObserverMetamerism.m')) | How a metameric match breaks across observers |
%[text:table]
%%
%[text] ## Learn more
%[text] - The full learning path with time estimates is in the examples folder README \
%[text] - The public API is documented in the class docstring: run `help IndividualCMF` \
%[text] - For the internal design (class layering, the four-stage pipeline, how to add a template) see `ARCHITECTURE.md` at [github.com/sfu-cs-vision-lab/individual-cmfs-matlab](https://github.com/sfu-cs-vision-lab/individual-cmfs-matlab) -- it lives in the repository, not in the installed toolbox

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
