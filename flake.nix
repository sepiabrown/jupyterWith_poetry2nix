{
  description = "fun with jupyterWith and poetry2nix";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-22.05"; 
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
    jupyterWith = {
      url = "github:tweag/jupyterWith";#/python39_and_poetry2nix"; /environment_variables_test"; 
      #inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs: with inputs; 
    {
      overlay = nixpkgs.lib.composeManyExtensions ([
        (final: prev: {
          poetry2nix = prev.poetry2nix.overrideScope' (p2nixfinal: p2nixprev: {
            # pyfinal & pyprev refers to python packages
            defaultPoetryOverrides = (p2nixprev.defaultPoetryOverrides.extend (pyfinal: pyprev:
              {
                ### Must needed to dodge infinite recursion ###
                python_selected = prev.python39;
                setuptools = (pyfinal.python_selected.pkgs.setuptools.overridePythonAttrs (old: {
                  catchConflicts = false;
                  format = "other";
                })).override {
                  inherit (pyfinal)
                    bootstrapped-pip
                    pipInstallHook;
                    #setuptoolsBuildHook
                };
                # With this, skipSetupToolsSCM in mk-poetry-dep.nix is not needed
                setuptools-scm = pyfinal.python_selected.pkgs.setuptools-scm.override {
                  inherit (pyfinal)
                    packaging
                    tomli
                    #typing-extensions
                    setuptools;
                };
                pip = pyfinal.python_selected.pkgs.pip.override {
                  inherit (pyfinal)
                    bootstrapped-pip
                    mock
                    scripttest
                    virtualenv
                    pretend
                    pytest
                    pip-tools;
                };
                ### Must needed to dodge infinite recursion (end) ###

                # needed by requests needed by twine
                idna = pyprev.idna.overridePythonAttrs (old: rec {
                  propagatedBuildInputs = builtins.filter (x: ! builtins.elem x [ ]) ((old.propagatedBuildInputs or [ ]) ++ [ pyfinal.flit-core ]);
                });
                nbconvert = pyprev.nbconvert.overridePythonAttrs (old: rec {
                  propagatedBuildInputs = builtins.filter (x: ! builtins.elem x [ ]) ((old.propagatedBuildInputs or [ ]) ++ [ pyfinal.packaging ]);
                });
              }));
          });
        })
      ] ++ (builtins.attrValues jupyterWith.overlays)
        ++ [
        (final: prev: {
          jupyterWith_python_custom = final.jupyterWith.override {
            python3 = self.python_custom.x86_64-linux;
          };
        })
        ]
      );
    } // (flake-utils.lib.eachDefaultSystem (system: # `//` : set appending behind output
      rec
      {
        pkgs = import nixpkgs {
          inherit system; #system = "x86_64-linux";
          config.allowUnfree = true;
          overlays = [ self.overlay ];
        };

        python_custom = pkgs.poetry2nix.mkPoetryEnv rec {
          projectDir = ./.;
          python = pkgs.python39;
        };

        pyproject = builtins.fromTOML (builtins.readFile ./pyproject.toml);
        depNames = builtins.attrNames pyproject.tool.poetry.dependencies;

        iPythonWithPackages = pkgs.jupyterWith_python_custom.kernels.iPythonWith {
          name = "ms-thesis--env";
          python3 = python_custom;
          packages = p:
            let
              ## Building the local package using the standard way.
              #myPythonPackage = p.buildPythonPackage {
              #  pname = "MyPythonPackage";
              #  version = "1.0";
              #  src = ./my-python-package;
              #};
              poetryDeps =
                builtins.map (name: builtins.getAttr name p) depNames;
            in
            poetryDeps; #++ [ myPythonPackage ];
        };

        jupyterEnvironment = (pkgs.jupyterWith_python_custom.jupyterlabWith {
          kernels = [ iPythonWithPackages ];
          #extraPackages = ps: [
          #];
        });
        devShells.default = pkgs.mkShell rec {
          packages = [
            python_custom
            jupyterEnvironment
          ];
        };
      }
    ));
}
