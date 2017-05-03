{ stdenv, fetchurl, gtk3, python3Packages, intltool,
  pango, cairo, librsvg, wrapGAppsHook, xdg_utils, graphviz }:

let
  inherit (python3Packages) python buildPythonApplication;
in buildPythonApplication rec {
  version = "4.2.5";
  name = "gramps-${version}";

  buildInputs = [ intltool wrapGAppsHook ];

  propagatedBuildInputs = with python3Packages; [ pygobject3 bsddb3 pycairo ] ++ [ gtk3 pango cairo librsvg xdg_utils graphviz ];

  # # Currently broken
  doCheck = false;

  src = fetchurl {
    url = "https://github.com/gramps-project/gramps/archive/v${version}.tar.gz";
    sha256 = "0gblb2agqszhrz8ccdzf26l2lpx7wwa6w24gxiwvgl5p2mr01qqx";
  };

  postUnpack = ''
    set -x
  '';


  setupPyBuildFlags = [ "--resourcepath" "$out/share/gramps/" ];
  # Same installPhase as in buildPythonApplication but without --old-and-unmanageble
  # install flag.
  # installPhase = ''
  #   runHook preInstall

  #   mkdir -p "$out/lib/${python.libPrefix}/site-packages"

  #   export PYTHONPATH="$out/lib/${python.libPrefix}/site-packages:$PYTHONPATH"

  #   ${python}/bin/${python.executable} setup.py install \
  #     --install-lib=$out/lib/${python.libPrefix}/site-packages \
  #     --prefix="$out"

  #   eapth="$out/lib/${python.libPrefix}"/site-packages/easy-install.pth
  #   if [ -e "$eapth" ]; then
  #       # move colliding easy_install.pth to specifically named one
  #       mv "$eapth" $(dirname "$eapth")/${name}.pth
  #   fi

  #   rm -f "$out/lib/${python.libPrefix}"/site-packages/site.py*

  #   runHook postInstall
  # '';

  meta = with stdenv.lib; {
    description = "Genealogy software";
    homepage = http://gramps-project.org;
    license = licenses.gpl2;
  };
}
