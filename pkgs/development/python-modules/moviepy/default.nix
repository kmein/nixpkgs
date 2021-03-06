{ lib, stdenv
, buildPythonPackage
, fetchPypi
, pythonAtLeast
, numpy
, decorator
, imageio
, imageio-ffmpeg
, proglog
, requests
, tqdm
# Advanced image processing (triples size of output)
, advancedProcessing ? false
, opencv3 ? null
, scikitimage ? null
, scikitlearn ? null
, scipy ? null
, matplotlib ? null
, youtube-dl ? null
}:

assert advancedProcessing -> (
  opencv3 != null && scikitimage != null && scikitlearn != null
  && scipy != null && matplotlib != null && youtube-dl != null);

buildPythonPackage rec {
  pname = "moviepy";
  version = "1.0.3";

  disabled = !(pythonAtLeast "3.4");

  src = fetchPypi {
    inherit pname version;
    sha256 = "2884e35d1788077db3ff89e763c5ba7bfddbd7ae9108c9bc809e7ba58fa433f5";
  };

  # No tests, require network connection
  doCheck = false;

  propagatedBuildInputs = [
    numpy decorator imageio imageio-ffmpeg tqdm requests proglog
  ] ++ (lib.optionals advancedProcessing [
    opencv3 scikitimage scikitlearn scipy matplotlib youtube-dl
  ]);

  meta = with lib; {
    description = "Video editing with Python";
    homepage = "https://zulko.github.io/moviepy/";
    license = licenses.mit;
  };

}
