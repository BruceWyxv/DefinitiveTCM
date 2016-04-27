classdef FitProperties < uint8
% Properties is an enumeration class for the properties array of the TCM
  enumeration
    SubstrateConductivity       (1)
    SubstrateDiffusivity        (2)
    SubstrateAnisoConductivity  (3)
    SubstrateAnisoDiffusivity   (4)
    FilmConductivity            (5)
    FilmDiffusivity             (6)
    KapitzaResistance           (7)
    SpotSize                    (8)
  end
  
  methods (Static)
    function array = GetArrayOfProperties()
    % Generate an array of all the properties
      array = enumeration(mfilename('class')); % Generic, so that if the class name changes this statement is still valie
    end
    
    function name = GetName(property)
    % Return a full-text name of a property
      switch property
        case FitProperties.SubstrateConductivity
          name = 'Substrate Conductivity';
          
        case FitProperties.SubstrateDiffusivity
          name = 'Substrate Diffusivity';
          
        case FitProperties.SubstrateAnisoConductivity
          name = 'Substrate Anisotropic Conductivity';
          
        case FitProperties.SubstrateAnisoDiffusivity
          name = 'Substrate Anisotropic Diffusivity';
          
        case FitProperties.FilmConductivity
          name = 'Film Conductivity';
          
        case FitProperties.FilmDiffusivity
          name = 'Film Diffusivity';
          
        case FitProperties.KapitzaResistance
          name = 'Kapitza Resistance';
          
        case FitProperties.SpotSize
          name = 'Convolved Spot Size';
      end
    end
  end
end

