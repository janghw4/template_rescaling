# MNI Template Rescaling
A MATLAB function for creating subject-specific rescaled MNI templates based on individual head measurements. 
This tool helps improve the anatomical accuracy of neuroimaging analyses by accounting for individual head shape variations.

## Features

Subject-specific scaling: Generate personalized MNI templates based on head measurements
Batch processing: Process multiple subjects efficiently
Flexible input: Support for struct-based measurements and CSV files
Comprehensive validation: Input validation and error handling
SPM integration: Seamless integration with SPM12 for neuroimaging workflows

## Requirements

- MATLAB
- SPM12 toolbox
- MNI template file in the same folder
  https://github.com/MASILab/PreQual/blob/master/src/APPS/synb0/atlases/mni_icbm152_t1_tal_nlin_asym_09c.nii.gz

### Basic usage

```matlab
% Define subject measurements (in cm)
measurements = struct();
measurements.lpa_to_rpa = 14.5;    % Left-right preauricular distance
measurements.depth = 19.2;         % Anterior-posterior depth
measurements.lpa_to_top = 13.8;    % LPA to top of head

% Create rescaled template
scaling_factors = create_rescaled_mni_template('sub001', measurements);
```

### Advanced options

```matlab
% With custom parameters
scaling_factors = create_rescaled_mni_template('sub001', measurements, ...
    'template_path', 'custom_template.nii', ...
    'output_dir', './results/', ...
    'spm_path', 'D:\SPM12', ...
    'interpolation', 2);
```

## Measurements Guide

- **lpa_to_rpa**: Distance between left and right preauricular points (supratragic notch) (cm)
- **depth**: Anterior-posterior head depth (cm)
- **lpa_to_top**: Distance from left preauricular point (supratragic notch) to top of head (cm)

## Output

The function creates:
- Rescaled MNI template file in subject-specific directory
- Scaling factors for each dimension [fx, fy, fz]

## Citation

If you use this toolbox in your research, please consider citing:
https://pmc.ncbi.nlm.nih.gov/articles/PMC11483030/



