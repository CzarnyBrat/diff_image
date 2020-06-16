import 'dart:io' as io;

import 'package:image/image.dart';
import 'helper_functions.dart';

class DiffImage{

  ///Returns a single number representing the difference between two RGB pixels
  static num _diffBetweenPixels(firstPixel, secondPixel, ignoreAlpha){
    var fRed = getRed(firstPixel);     var fGreen = getGreen(firstPixel);
    var fBlue = getBlue(firstPixel);   var fAlpha = getAlpha(firstPixel);
    var sRed = getRed(secondPixel);    var sGreen = getGreen(secondPixel);
    var sBlue = getBlue(secondPixel);  var sAlpha = getAlpha(secondPixel);

    num diff = (fRed-sRed).abs() + (fGreen-sGreen).abs() + (fBlue-sBlue).abs();

    if( ignoreAlpha ) {diff = (diff/255) / 3;}
    else {
      diff += (fAlpha-sAlpha).abs();
      diff = (diff/255) / 4;
    }

    return diff;
  }

  ///Returns a single number representing the average difference between each pixel
  static Future<dynamic> compareFromUrl(
      firstImgSrc, secondImgSrc,
      {ignoreAlpha=true, asPercentage=true, saveDiff=false, returnDiffImage=false}
  ) async {

    var firstImg = await getImg(firstImgSrc);
    if( firstImg is Exception ) throw firstImg;

    var secondImg = await getImg(secondImgSrc);
    if( secondImg is Exception ) throw secondImg;

    if( !haveSameSize(firstImg, secondImg) ){
      throw UnsupportedError('Currently we need images of same width and height');
    }


    final diff = await _getImagesDiff(
      firstImg, secondImg,
      ignoreAlpha: ignoreAlpha,
      asPercentage: asPercentage,
      saveDiff: saveDiff,
      returnDiffImage: returnDiffImage
    );

    return diff;
  }

  // Returns a single number representing the average difference between each pixel
  static Future<dynamic> compareFromFiles(
      io.File firstFile, io.File secondFile,
      {ignoreAlpha=true, asPercentage=true, saveDiff=false, returnDiffImage=true}
  ) async {

    var firstImg = decodeImage(await firstFile.readAsBytes());
    if( firstImg is Exception ) throw firstImg;

    var secondImg = decodeImage(await secondFile.readAsBytes());
    if( secondImg is Exception ) throw secondImg;

    if( !haveSameSize(firstImg, secondImg) ){
      throw UnsupportedError('Currently we need images of same width and height');
    }


    final diff = await _getImagesDiff(
        firstImg, secondImg,
        ignoreAlpha: ignoreAlpha,
        asPercentage: asPercentage,
        saveDiff: saveDiff,
        returnDiffImage: returnDiffImage
    );

    return diff;
  }

  static Future<dynamic> _getImagesDiff(
    Image firstImage, Image secondImage,
    {bool ignoreAlpha, bool asPercentage, bool saveDiff, bool returnDiffImage}
  ) async {
    var width = firstImage.width; var height = firstImage.height;
    var diff = 0.0;

    //Create an image to show the differences
    var diffImg = Image(width, height);

    for(var i=0; i<width; i++){
      var diffAtPixel, firstPixel, secondPixel;
      for(var j=0; j<height; j++){
        firstPixel = firstImage.getPixel(i, j);
        secondPixel = secondImage.getPixel(i, j);

        diffAtPixel = _diffBetweenPixels(firstPixel, secondPixel, ignoreAlpha);
        diff += diffAtPixel;

        //Shows in red the different pixels and in semitransparent the same ones
        diffImg.setPixel(i, j, selectColor(firstPixel, secondPixel, diffAtPixel));
      }
    }

    diff /= height*width;

    if( asPercentage ) diff *= 100;

    if( saveDiff ) {
      await io.File('DiffImg.png').writeAsBytes(encodePng(diffImg));
    }

    if( returnDiffImage ) {
      return encodePng(diffImg);
    } else {
      return diff;
    }

  }

}