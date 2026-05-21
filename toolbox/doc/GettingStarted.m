%[text] # Getting Started
%[text] The **Individual Cone Fundamentals Toolbox** computes observer-specific LMS cone spectral sensitivities, and quantities derived from them (RGB color matching functions, CIE XYZ, photopic luminance $V^*(\\lambda)$, chromaticity), from biophysical parameters: opsin genotype, age, retinal field size, and lens / macular / photopigment optical densities.
%[text] The defaults reproduce the CIE 170-1:2006 physiological standard observers, and every input can be overridden individually to model a specific observer or to study one biophysical parameter in isolation.
%[text] This guide is a one-minute orientation and a map of the worked examples. Run the cell below, then open whichever example matches what you want to do.
%%
%[text] ## A first observer
%[text] `IndividualCMF` with no arguments returns the CIE 2006 10 deg standard observer. Evaluate any cone with `obs.L(wl)` / `obs.M(wl)` / `obs.S(wl)`, or all three with `obs.LMS(wl)`, passing wavelengths as a column vector. The `plotLMS` wrapper draws the three peak-normalized fundamentals.
obs = IndividualCMF();
obs.plotLMS(Title="CIE 2006 10 deg cone fundamentals");
xlim([380 780]); ylim([0 1.05])
%%
%[text] ## Example gallery
%[text] The toolbox ships 18 worked examples (plain-text Live Scripts), roughly ordered from foundations to advanced usage. Click an example to open it.
%[text:table]
%[text] | # | Example | What it covers |
%[text] | --- | --- | --- |
%[text] | 01 | [The Basics](matlab:open('Example01_Basics.m')) | Construct an observer, evaluate cones, plot, normalization |
%[text] | 02 | [Standard Observers](matlab:open('Example02_StandardObservers.m')) | CIE 2006 2 deg and 10 deg observers; XYZ color matching functions |
%[text] | 03 | [Field Size Effects](matlab:open('Example03_FieldSizeEffects.m')) | Macular pigment and photopigment OD vs field size |
%[text] | 04 | [Aging Effects](matlab:open('Example04_AgingEffects.m')) | Lens yellowing and the `LensModel` choice |
%[text] | 05 | [Genetic Variants](matlab:open('Example05_GeneticVariants.m')) | Ser180Ala polymorphism, hybrid cones, `Genotype` |
%[text] | 06 | [Photopigment Models](matlab:open('Example06_PhotopigmentModels.m')) | Stockman-Rider 2023 vs Govardovskii 2000 templates |
%[text] | 07 | [Computational Pipeline](matlab:open('Example07_ComputationalPipeline.m')) | The four-stage pipeline via the public API |
%[text] | 08 | [Output Formats](matlab:open('Example08_OutputFormats.m')) | `energy` / `quantal` / `absorptance` / `absorbance`, `LogOutput` |
%[text] | 09 | [RGB Color Matching](matlab:open('Example09_RGBColorMatching.m')) | RGB CMFs, negative lobes, custom display primaries |
%[text] | 10 | [Chromaticity Diagrams](matlab:open('Example10_ChromaticityDiagrams.m')) | lm and CIE xy chromaticity, spectral locus |
%[text] | 11 | [Photopic Luminance](matlab:open('Example11_Luminance.m')) | $V^*(\\lambda)$ and MacLeod-Boynton coordinates |
%[text] | 12 | [Observer Comparison](matlab:open('Example12_ObserverComparison.m')) | `compareTo`, RMS metrics, multi-observer overlays |
%[text] | 13 | [Dichromacy](matlab:open('Example13_Dichromacy.m')) | Protan / deutan / tritan via zero optical density |
%[text] | 14 | [Advanced Customization](matlab:open('Example14_AdvancedCustomization.m')) | Every parameter; `getParameters` round-trip |
%[text] | 15 | [Data Export](matlab:open('Example15_DataExport.m')) | `evaluate`, CSV and MAT export |
%[text] | 16 | [Normalization Methods](matlab:open('Example16_NormalizationMethods.m')) | Continuous vs Sampled peak normalization |
%[text] | 17 | [Publication Figures](matlab:open('Example17_PublicationFigures.m')) | Multi-panel composites; vector export |
%[text] | 18 | [Observer Metamerism](matlab:open('Example18_ObserverMetamerism.m')) | How a metameric match breaks across observers |
%[text:table]
%%
%[text] ## Learn more
%[text] - The full learning path with time estimates is in the examples folder README \
%[text] - The public API is documented in the class docstring: run `help IndividualCMF` \
%[text] - For the internal design (class layering, the four-stage pipeline, how to add a template) see `ARCHITECTURE.md` in the repository

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
