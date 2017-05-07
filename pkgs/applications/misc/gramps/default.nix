{ stdenv, fetchurl, gtk3, python3Packages, intltool,
  pango, cairo, librsvg, wrapGAppsHook, xdg_utils, graphviz }:

let
  inherit (python3Packages) python buildPythonApplication;
in buildPythonApplication rec {
  version = "4.2.5";
  name = "gramps-${version}";

  buildInputs = [ intltool wrapGAppsHook ];

  propagatedBuildInputs = with python3Packages; [ pygobject3 bsddb3 pycairo pillow PyICU ] ++ [ gtk3 pango cairo librsvg xdg_utils graphviz ];

  # # Currently broken
  doCheck = false;

  src = fetchurl {
    url = "https://github.com/gramps-project/gramps/archive/v${version}.tar.gz";
    sha256 = "0gblb2agqszhrz8ccdzf26l2lpx7wwa6w24gxiwvgl5p2mr01qqx";
  };

  buildPhase = ''
    python setup.py build
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/${python.sitePackages}"
    export PYTHONPATH="$out/${python.sitePackages}:$PYTHONPATH"
    ${python}/bin/${python.executable} setup.py install \
      --install-lib=$out/${python.sitePackages} \
      --prefix="$out" \
      --resourcepath=$out/share
    runHook postInstall
  '';

  meta = with stdenv.lib; {
    description = "Genealogy software";
    homepage = http://gramps-project.org;
    license = licenses.gpl2;
  };
}
