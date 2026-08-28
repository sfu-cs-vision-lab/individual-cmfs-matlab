function regen_govardovskii()
% REGEN_GOVARDOVSKII  Regenerate tests/data/govardovskii_reference.csv.
%
%   Writes an independent reference for the Govardovskii A1 nomogram by
%   coding the published equations directly. It deliberately does NOT call
%   Nomograms or any toolbox class: the fixture exists to cross-check the
%   toolbox, and generating it from the toolbox would make it a copy of the
%   toolbox's own output. Same principle as tests/parity/regen_golden.m.
%
%   SOURCE
%       Govardovskii, V.I., Fyhrquist, N., Reuter, T., Kuzmin, D.G. &
%       Donner, K. (2000). In search of the visual pigment template.
%       Visual Neuroscience, 17(4), 509-528.
%       Alpha band  Eq. (1) and Eq. (2), journal p. 515.
%       Beta band   Eq. (4), Eq. (5a), Eq. (5b), journal p. 516.
%       All coefficients below are transcribed verbatim from those
%       equations; nothing is derived or re-rounded.
%
%   OBSERVER CONFIGURATION
%       lambda-max  560 / 530 / 430 nm for L / M / S. These are the integer
%                   values ReferenceParityTest shifts the CIE defaults to,
%                   and they land on the output grid, which is what lets
%                   the at-lambda-max normalization below be exact.
%       optical density 0.3 for all three cones.
%       grid        380:1:780 nm.
%
%   NORMALIZATION CONVENTION -- the thing whose absence caused trouble
%       Each column is relative retinal absorptance
%           (1 - 10^(-OD*A)) / (1 - 10^(-OD))
%       divided by its own value AT lambda-max, so every column equals
%       exactly 1 at 560 / 530 / 430 nm respectively.
%
%       This is NOT the toolbox's convention. IndividualCMF normalizes to
%       the maximum of the alpha+beta curve, which sits slightly away from
%       lambda-max -- for A2 at 420.7 nm the argmax is 416.75 nm. The two
%       differ here by 1.9e-07 (L) to 8.1e-06 (S).
%
%       The fixture keeps the at-lambda-max convention on purpose, so it
%       stays a record of the legacy implementation rather than tracking
%       whatever the toolbox currently does.
%       ReferenceParityTest.testMatchLegacyGovardovskii applies the same
%       convention to raw toolbox output before comparing, which is what
%       lets that comparison hold at AbsTol 1e-10.
%
%   USAGE
%       cd tests/parity; regen_govardovskii
%
%   Copyright 2025-2026 Alexander Forsythe and Brian Funt. Simon Fraser University.

    arguments
    end

    lambdaMax = [560, 530, 430];
    opticalDensity = 0.3;
    wavelengths = (380:1:780)';

    absorptance = zeros(numel(wavelengths), 3);
    for cone = 1:3
        absorbance = govardovskiiA1(wavelengths, lambdaMax(cone));
        relative = (1 - 10.^(-opticalDensity .* absorbance)) / ...
                   (1 - 10^(-opticalDensity));

        % At-lambda-max anchoring. lambdaMax is on the grid by
        % construction, so this is an exact lookup, not an interpolation.
        anchor = relative(wavelengths == lambdaMax(cone));
        absorptance(:, cone) = relative / anchor;
    end

    outputFile = fullfile(fileparts(mfilename('fullpath')), '..', 'data', ...
        'govardovskii_reference.csv');
    result = table(wavelengths, absorptance(:,1), absorptance(:,2), absorptance(:,3), ...
        VariableNames=["nm", "L_absorptance", "M_absorptance", "S_absorptance"]);
    writetable(result, outputFile);

    fprintf('Wrote %s\n', outputFile);
    fprintf('  %d rows, %g-%g nm\n', height(result), wavelengths(1), wavelengths(end));
    for cone = 1:3
        fprintf('  lambda-max %d nm: column max %.12f\n', ...
            lambdaMax(cone), max(absorptance(:, cone)));
    end
end

function absorbance = govardovskiiA1(wavelengths, lambdaMax)
% GOVARDOVSKIIA1  Alpha + beta absorbance, Govardovskii et al. (2000).
%
%   An independent transcription of the published equations. Kept separate
%   from Nomograms on purpose -- see the file header.

    % Eq. (1), p. 515. Constants as printed in the text following it.
    A = 69.7;
    B = 28;
    C = -14.9;
    D = 0.674;
    b = 0.922;
    c = 1.104;

    % Eq. (2), p. 515, verbatim.
    a = 0.8795 + 0.0459 * exp(-((lambdaMax - 300)^2) / 11940);

    x = lambdaMax ./ wavelengths;
    alphaBand = 1 ./ (exp(A * (a - x)) + exp(B * (b - x)) + exp(C * (c - x)) + D);

    % Eq. (4) with Eqs. (5a) and (5b), p. 516. A_beta is fixed at 0.26 for
    % A1 pigments, per the text on that page.
    aBeta = 0.26;
    lambdaMaxBeta = 189 + 0.315 * lambdaMax;
    betaWidth = -40.5 + 0.195 * lambdaMax;
    betaBand = aBeta * exp(-((wavelengths - lambdaMaxBeta) / betaWidth).^2);

    absorbance = alphaBand + betaBand;
    absorbance(absorbance < 0) = 0;
end
