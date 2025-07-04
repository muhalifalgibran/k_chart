import 'dart:async' show StreamSink;

import 'package:flutter/material.dart';
import 'package:k_chart/utils/number_util.dart';

import '../entity/info_window_entity.dart';
import '../entity/k_line_entity.dart';
import '../utils/date_format_util.dart';
import 'base_chart_painter.dart';
import 'base_chart_renderer.dart';
import 'main_renderer.dart';
import 'secondary_renderer.dart';
import 'vol_renderer.dart';

class TrendLine {
  final Offset p1;
  final Offset p2;
  final double maxHeight;
  final double scale;

  TrendLine(this.p1, this.p2, this.maxHeight, this.scale);
}

double? trendLineX;

double getTrendLineX() {
  return trendLineX ?? 0;
}

class ChartPainter extends BaseChartPainter {
  final List<TrendLine> lines; //For TrendLine
  final bool isTrendLine; //For TrendLine
  bool isrecordingCord = false; //For TrendLine
  final double selectY; //For TrendLine
  static get maxScrollX => BaseChartPainter.maxScrollX;
  late BaseChartRenderer mMainRenderer;
  BaseChartRenderer? mVolRenderer, mSecondaryRenderer;
  MainRenderer? mMarkerRenderer;
  StreamSink<InfoWindowEntity?>? sink;
  Color? upColor, dnColor;
  Color? ma5Color, ma10Color, ma30Color;
  Color? volColor;
  Color? macdColor, difColor, deaColor, jColor;
  int fixedLength;
  List<int> maDayList;
  final ChartColors chartColors;
  late Paint selectPointPaint, selectorBorderPaint, nowPricePaint;
  final ChartStyle chartStyle;
  final bool hideGrid;
  final bool showNowPrice;
  final VerticalTextAlignment verticalTextAlignment;
  final String decimalSeparator;
  final int? decimalPlaces;
  final Color onHoverShadowColor;
  final bool isShowMarker;
  final MarkerStyle markerStyle;

  ChartPainter(
    this.chartStyle,
    this.chartColors, {
    required this.lines, //For TrendLine
    required this.isTrendLine, //For TrendLine
    required this.selectY, //For TrendLine
    required datas,
    required scaleX,
    required scrollX,
    required isLongPass,
    required selectX,
    required xFrontPadding,
    isOnTap,
    isTapShowInfoDialog,
    required this.verticalTextAlignment,
    required this.decimalSeparator,
    required this.onHoverShadowColor,
    this.decimalPlaces,
    mainState,
    volHidden,
    secondaryState,
    this.sink,
    bool isLine = false,
    this.hideGrid = false,
    this.showNowPrice = true,
    this.fixedLength = 2,
    this.maDayList = const [5, 10, 20],
    this.isShowMarker = false,
    this.markerStyle = const MarkerStyle(),
  }) : super(chartStyle,
            datas: datas,
            scaleX: scaleX,
            scrollX: scrollX,
            isLongPress: isLongPass,
            isOnTap: isOnTap,
            isTapShowInfoDialog: isTapShowInfoDialog,
            selectX: selectX,
            mainState: mainState,
            volHidden: volHidden,
            secondaryState: secondaryState,
            xFrontPadding: xFrontPadding,
            isLine: isLine) {
    selectPointPaint = Paint()
      ..isAntiAlias = true
      ..strokeWidth = 0.5
      ..color = this.chartColors.selectFillColor;
    selectorBorderPaint = Paint()
      ..isAntiAlias = true
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke
      ..color = this.chartColors.selectBorderColor;
    nowPricePaint = Paint()
      ..strokeWidth = this.chartStyle.nowPriceLineWidth
      ..isAntiAlias = true;
  }

  @override
  void initChartRenderer() {
    if (datas != null && datas!.isNotEmpty) {
      var t = datas![0];
      fixedLength =
          NumberUtil.getMaxDecimalLength(t.open, t.close, t.high, t.low);
    }
    mMainRenderer = MainRenderer(
      mMainRect,
      mMainMaxValue,
      mMainMinValue,
      mTopPadding,
      mainState,
      isLine,
      fixedLength,
      this.chartStyle,
      this.chartColors,
      this.scaleX,
      verticalTextAlignment,
      decimalSeparator,
      decimalPlaces,
      maDayList,
    );
    if (mVolRect != null) {
      mVolRenderer = VolRenderer(
          mVolRect!,
          mVolMaxValue,
          mVolMinValue,
          mChildPadding,
          fixedLength,
          this.chartStyle,
          this.chartColors,
          this.decimalSeparator);
    }
    if (mSecondaryRect != null) {
      mSecondaryRenderer = SecondaryRenderer(
        mSecondaryRect!,
        mSecondaryMaxValue,
        mSecondaryMinValue,
        mChildPadding,
        secondaryState,
        fixedLength,
        chartStyle,
        chartColors,
        decimalSeparator,
      );
    }

    if (mMarkerRenderer == null) {
      mMarkerRenderer = MainRenderer(
        mMainRect,
        mMainMaxValue,
        mMainMinValue,
        mTopPadding,
        mainState,
        isLine,
        fixedLength,
        this.chartStyle,
        this.chartColors,
        this.scaleX,
        verticalTextAlignment,
        decimalSeparator,
        decimalPlaces,
      );
    }
  }

  @override
  void drawBg(Canvas canvas, Size size) {
    Paint mBgPaint = Paint();
    Gradient mBgGradient = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: chartColors.bgColor,
    );
    Rect mainRect =
        Rect.fromLTRB(0, 0, mMainRect.width, mMainRect.height + mTopPadding);
    canvas.drawRect(
        mainRect, mBgPaint..shader = mBgGradient.createShader(mainRect));

    if (mVolRect != null) {
      Rect volRect = Rect.fromLTRB(
          0, mVolRect!.top - mChildPadding, mVolRect!.width, mVolRect!.bottom);
      canvas.drawRect(
          volRect, mBgPaint..shader = mBgGradient.createShader(volRect));
    }

    if (mSecondaryRect != null) {
      Rect secondaryRect = Rect.fromLTRB(0, mSecondaryRect!.top - mChildPadding,
          mSecondaryRect!.width, mSecondaryRect!.bottom);
      canvas.drawRect(secondaryRect,
          mBgPaint..shader = mBgGradient.createShader(secondaryRect));
    }
    Rect dateRect =
        Rect.fromLTRB(0, size.height - mBottomPadding, size.width, size.height);
    canvas.drawRect(
        dateRect, mBgPaint..shader = mBgGradient.createShader(dateRect));
  }

  @override
  void drawGrid(canvas) {
    if (!hideGrid) {
      mMainRenderer.drawGrid(canvas, mGridRows, mGridColumns);
      mVolRenderer?.drawGrid(canvas, mGridRows, mGridColumns);
      mSecondaryRenderer?.drawGrid(canvas, mGridRows, mGridColumns);
    }
  }

  @override
  void drawChart(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(mTranslateX * scaleX, 0.0);
    canvas.scale(scaleX, 1.0);
    for (int i = mStartIndex; datas != null && i <= mStopIndex; i++) {
      KLineEntity? curPoint = datas?[i];
      if (curPoint == null) continue;
      KLineEntity lastPoint = i == 0 ? curPoint : datas![i - 1];
      double curX = getX(i);
      double lastX = i == 0 ? curX : getX(i - 1);

      mMainRenderer.drawChart(lastPoint, curPoint, lastX, curX, size, canvas);
      mVolRenderer?.drawChart(lastPoint, curPoint, lastX, curX, size, canvas);
      if (isShowMarker) {
        if (curPoint.isBuy == true)
          mMarkerRenderer?.drawBuy(
            lastPoint,
            curPoint,
            lastX,
            curX,
            size,
            canvas,
            markerStyle,
          );

        if (curPoint.isSell == true)
          mMarkerRenderer?.drawSell(
            lastPoint,
            curPoint,
            lastX,
            curX,
            size,
            canvas,
            markerStyle,
          );
      }
      mSecondaryRenderer?.drawChart(
          lastPoint, curPoint, lastX, curX, size, canvas);
    }

    if ((isLongPress == true || (isTapShowInfoDialog && isOnTap)) &&
        isTrendLine == false) {
      drawOverlay(canvas, size);
      drawCrossLine(canvas, size);
    }
    if (isTrendLine == true) drawTrendLines(canvas, size);
    canvas.restore();
  }

  @override
  void drawVerticalText(canvas) {
    var textStyle = getTextStyle(this.chartColors.defaultTextColor);
    if (!hideGrid) {
      mMainRenderer.drawVerticalText(canvas, textStyle, mGridRows);
    }
    mVolRenderer?.drawVerticalText(canvas, textStyle, mGridRows);
    mSecondaryRenderer?.drawVerticalText(canvas, textStyle, mGridRows);
  }

  @override
  void drawDate(Canvas canvas, Size size) {
    if (datas == null) return;

    double columnSpace = size.width / mGridColumns;
    double startX = getX(mStartIndex) - mPointWidth / 2;
    double stopX = getX(mStopIndex) + mPointWidth / 2;
    double x = 0.0;
    double y = 0.0;
    for (var i = 0; i <= mGridColumns; ++i) {
      double translateX = xToTranslateX(columnSpace * i);

      if (translateX >= startX && translateX <= stopX) {
        int index = indexOfTranslateX(translateX);

        if (datas?[index] == null) continue;
        TextPainter tp = getTextPainter(getDate(datas![index].time), null);
        y = size.height - (mBottomPadding - tp.height) / 2 - tp.height;
        x = columnSpace * i - tp.width / 2;
        // Prevent date text out of canvas
        if (x < 0) x = 0;
        if (x > size.width - tp.width) x = size.width - tp.width;
        tp.paint(canvas, Offset(x, y));
      }
    }

//    double translateX = xToTranslateX(0);
//    if (translateX >= startX && translateX <= stopX) {
//      TextPainter tp = getTextPainter(getDate(datas[mStartIndex].id));
//      tp.paint(canvas, Offset(0, y));
//    }
//    translateX = xToTranslateX(size.width);
//    if (translateX >= startX && translateX <= stopX) {
//      TextPainter tp = getTextPainter(getDate(datas[mStopIndex].id));
//      tp.paint(canvas, Offset(size.width - tp.width, y));
//    }
  }

  @override
  void drawCrossLineText(Canvas canvas, Size size) {
    var index = calculateSelectedX(selectX);
    KLineEntity point = getItem(index);

    TextPainter tp = getTextPainter(
        NumberUtil.format(point.close.toString(), decimalSeparator,
            decimal: decimalPlaces),
        chartColors.crossTextColor);
    double textHeight = tp.height;
    double textWidth = tp.width;

    double w1 = 5;
    double w2 = 3;
    double r = textHeight / 2 + w2;
    double y = getMainY(point.close);
    double x;
    bool isLeft = false;
    if (translateXtoX(getX(index)) < mWidth / 2) {
      isLeft = false;
      x = 1;
      Path path = new Path();
      path.moveTo(x, y - r);
      path.lineTo(x, y + r);
      path.lineTo(textWidth + 2 * w1, y + r);
      path.lineTo(textWidth + 2 * w1 + w2, y);
      path.lineTo(textWidth + 2 * w1, y - r);
      path.close();
      canvas.drawPath(path, selectPointPaint);
      canvas.drawPath(path, selectorBorderPaint);
      tp.paint(canvas, Offset(x + w1, y - textHeight / 2));
    } else {
      isLeft = true;
      x = mWidth - textWidth - 1 - 2 * w1 - w2;
      Path path = new Path();
      path.moveTo(x, y);
      path.lineTo(x + w2, y + r);
      path.lineTo(mWidth - 2, y + r);
      path.lineTo(mWidth - 2, y - r);
      path.lineTo(x + w2, y - r);
      path.close();
      canvas.drawPath(path, selectPointPaint);
      canvas.drawPath(path, selectorBorderPaint);
      tp.paint(canvas, Offset(x + w1 + w2, y - textHeight / 2));
    }

    TextPainter dateTp =
        getTextPainter(getDate(point.time), chartColors.crossTextColor);
    textWidth = dateTp.width;
    r = textHeight / 2;
    x = translateXtoX(getX(index));
    y = size.height - mBottomPadding;

    if (x < textWidth + 2 * w1) {
      x = 1 + textWidth / 2 + w1;
    } else if (mWidth - x < textWidth + 2 * w1) {
      x = mWidth - 1 - textWidth / 2 - w1;
    }
    double baseLine = textHeight / 2;
    canvas.drawRect(
        Rect.fromLTRB(x - textWidth / 2 - w1, y, x + textWidth / 2 + w1,
            y + baseLine + r),
        selectPointPaint);
    canvas.drawRect(
        Rect.fromLTRB(x - textWidth / 2 - w1, y, x + textWidth / 2 + w1,
            y + baseLine + r),
        selectorBorderPaint);

    dateTp.paint(canvas, Offset(x - textWidth / 2, y));
    //长按显示这条数据详情
    sink?.add(InfoWindowEntity(point, isLeft: isLeft));
  }

  @override
  void drawText(Canvas canvas, KLineEntity data, double x) {
    //长按显示按中的数据
    if (isLongPress || (isTapShowInfoDialog && isOnTap)) {
      var index = calculateSelectedX(selectX);
      data = getItem(index);
    }
    //松开显示最后一条数据
    mMainRenderer.drawText(canvas, data, x);
    mVolRenderer?.drawText(canvas, data, x);
    mSecondaryRenderer?.drawText(canvas, data, x);
  }

  @override
  void drawMaxAndMin(Canvas canvas) {
    if (isLine == true) return;
    double lineSize = 20;
    double lineToTextOffset = 5;

    Paint linePaint = Paint()
      ..strokeWidth = 1
      ..color = chartColors.minColor;

    //绘制最大值和最小值
    double x = translateXtoX(getX(mMainMinIndex));
    double y = getMainY(mMainLowMinValue);
    if (x < mWidth / 2) {
      //画右边
      TextPainter tp = getTextPainter(
        format(mMainLowMinValue.toString(), decimalSeparator,
            decimal: decimalPlaces),
        chartColors.minColor,
      );

      canvas.drawLine(
        Offset(x, y),
        Offset(x + lineSize, y),
        linePaint,
      );

      tp.paint(
        canvas,
        Offset(
          x + lineSize + lineToTextOffset,
          y - tp.height / 2,
        ),
      );
    } else {
      TextPainter tp = getTextPainter(
        format(
          mMainLowMinValue.toString(),
          decimalSeparator,
          decimal: decimalPlaces,
        ),
        chartColors.minColor,
      );

      canvas.drawLine(
        Offset(x, y),
        Offset(x - lineSize, y),
        linePaint,
      );

      tp.paint(
        canvas,
        Offset(
          x - tp.width - lineSize - lineToTextOffset,
          y - tp.height / 2,
        ),
      );
    }
    x = translateXtoX(getX(mMainMaxIndex));
    y = getMainY(mMainHighMaxValue);
    if (x < mWidth / 2) {
      //画右边
      TextPainter tp = getTextPainter(
        format(
          mMainHighMaxValue.toString(),
          decimalSeparator,
          decimal: decimalPlaces,
        ),
        chartColors.maxColor,
      );

      canvas.drawLine(
        Offset(x, y),
        Offset(x + lineSize, y),
        linePaint,
      );

      tp.paint(
        canvas,
        Offset(
          x + lineSize + lineToTextOffset,
          y - tp.height / 2,
        ),
      );
    } else {
      TextPainter tp = getTextPainter(
        format(
          mMainHighMaxValue.toString(),
          decimalSeparator,
          decimal: decimalPlaces,
        ),
        chartColors.maxColor,
      );

      canvas.drawLine(
        Offset(x, y),
        Offset(x - lineSize, y),
        linePaint,
      );

      tp.paint(
        canvas,
        Offset(
          x - tp.width - lineSize - lineToTextOffset,
          y - tp.height / 2,
        ),
      );
    }
  }

  @override
  void drawNowPrice(Canvas canvas) {
    if (!this.showNowPrice) {
      return;
    }

    if (datas == null) {
      return;
    }

    double value = datas!.last.close;
    double y = getMainY(value);

    //视图展示区域边界值绘制
    if (y > getMainY(mMainLowMinValue)) {
      y = getMainY(mMainLowMinValue);
    }

    if (y < getMainY(mMainHighMaxValue)) {
      y = getMainY(mMainHighMaxValue);
    }

    nowPricePaint
      ..color = value >= datas!.last.open
          ? this.chartColors.nowPriceUpColor
          : this.chartColors.nowPriceDnColor;
    //先画横线
    double startX = 0;
    final max = -mTranslateX + mWidth / scaleX;
    final space =
        this.chartStyle.nowPriceLineSpan + this.chartStyle.nowPriceLineLength;
    while (startX < max) {
      canvas.drawLine(
          Offset(startX, y),
          Offset(startX + this.chartStyle.nowPriceLineLength, y),
          nowPricePaint);
      startX += space;
    }
    //再画背景和文本
    TextPainter tp = getTextPainter(
        format(
          value.toString(),
          decimalSeparator,
          decimal: decimalPlaces,
        ),
        value >= datas!.last.open
            ? this.chartColors.nowPriceUpTextColor
            : this.chartColors.nowPriceDnTextColor,
        customStyle: TextStyle(
            fontSize: 10,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w700,
            color: value >= datas!.last.open
                ? this.chartColors.nowPriceUpTextColor
                : this.chartColors.nowPriceDnTextColor));

    double offsetX;
    switch (verticalTextAlignment) {
      case VerticalTextAlignment.left:
        offsetX = 0;
        break;
      case VerticalTextAlignment.right:
        offsetX = mWidth - tp.width - 4;
        break;
    }

    double top = y - tp.height / 2;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTRB(offsetX - 2, top - 2, offsetX + tp.width + 2,
                top + tp.height + 2),
            Radius.circular(4.0)),
        nowPricePaint);
    tp.paint(canvas, Offset(offsetX, top));
  }

//For TrendLine
  void drawTrendLines(Canvas canvas, Size size) {
    var index = calculateSelectedX(selectX);
    Paint paintY = Paint()
      ..color = Colors.orange
      ..strokeWidth = 1
      ..isAntiAlias = true;
    double x = getX(index);
    trendLineX = x;

    double y = selectY;
    // getMainY(point.close);

    // k线图竖线
    canvas.drawLine(Offset(x, mTopPadding),
        Offset(x, size.height - mBottomPadding), paintY);
    Paint paintX = Paint()
      ..color = Colors.orangeAccent
      ..strokeWidth = 1
      ..isAntiAlias = true;
    Paint paint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(-mTranslateX, y),
        Offset(-mTranslateX + mWidth / scaleX, y), paintX);
    if (scaleX >= 1) {
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(x, y), height: 15.0 * scaleX, width: 15.0),
          paint);
    } else {
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(x, y), height: 10.0, width: 10.0 / scaleX),
          paint);
    }
    if (lines.length >= 1) {
      lines.forEach((element) {
        var y1 = -((element.p1.dy - 35) / element.scale) + element.maxHeight;
        var y2 = -((element.p2.dy - 35) / element.scale) + element.maxHeight;
        var a = (trendLineMax! - y1) * trendLineScale! + trendLineContentRec!;
        var b = (trendLineMax! - y2) * trendLineScale! + trendLineContentRec!;
        var p1 = Offset(element.p1.dx, a);
        var p2 = Offset(element.p2.dx, b);
        canvas.drawLine(
            p1,
            element.p2 == Offset(-1, -1) ? Offset(x, y) : p2,
            Paint()
              ..color = Colors.yellow
              ..strokeWidth = 2);
      });
    }
  }

  void drawOverlay(Canvas canvas, Size size) {
    // Membuat kuas untuk menggambar kotak
    final paint = Paint()
      ..color = onHoverShadowColor // Warna kotak
      ..strokeWidth = 4
      ..style = PaintingStyle.fill;

    var index = calculateSelectedX(selectX);

    double x = getX(index);
    double gap = this.chartStyle.vCrossWidth / 2;

    double xLeft = 0;
    double xRight = getX(index + 1);

    // Mendefinisikan kotak
    final rect =
        Rect.fromLTWH(xLeft, 0, x - gap, size.height); // (x, y, lebar, tinggi)
    final rect2 = Rect.fromLTWH(
        xRight - 5, 0, size.width - gap, size.height); // (x, y, lebar, tinggi)

    // Menggambar kotak di canvas
    canvas.drawRect(rect, paint);
    canvas.drawRect(rect2, paint);
  }

  ///画交叉线
  void drawCrossLine(Canvas canvas, Size size) {
    var index = calculateSelectedX(selectX);
    KLineEntity point = getItem(index);
    Paint paintY = Paint()
      ..color = this.chartColors.vCrossColor
      ..strokeWidth = this.chartStyle.vCrossWidth
      ..isAntiAlias = true;
    double x = getX(index);
    double y = getMainY(point.close);
    // k线图竖线
    canvas.drawLine(Offset(x, mTopPadding),
        Offset(x, size.height - mBottomPadding), paintY);

    Paint paintX = Paint()
      ..color = this.chartColors.hCrossColor
      ..strokeWidth = this.chartStyle.hCrossWidth
      ..isAntiAlias = true;
    // k线图横线
    canvas.drawLine(Offset(-mTranslateX, y),
        Offset(-mTranslateX + mWidth / scaleX, y), paintX);
    if (scaleX >= 1) {
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(x, y), height: 2.0 * scaleX, width: 2.0),
          paintX);
    } else {
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(x, y), height: 2.0, width: 2.0 / scaleX),
          paintX);
    }
  }

  TextPainter getTextPainter(text, color, {TextStyle? customStyle}) {
    if (color == null) {
      color = this.chartColors.defaultTextColor;
    }
    TextSpan span =
        TextSpan(text: "$text", style: customStyle ?? getTextStyle(color));
    TextPainter tp = TextPainter(text: span, textDirection: TextDirection.ltr);
    tp.layout();
    return tp;
  }

  String getDate(int? date) => dateFormat(
      DateTime.fromMillisecondsSinceEpoch(
          date ?? DateTime.now().millisecondsSinceEpoch),
      mFormats);

  double getMainY(double y) => mMainRenderer.getY(y);

  /// 点是否在SecondaryRect中
  bool isInSecondaryRect(Offset point) {
    return mSecondaryRect?.contains(point) ?? false;
  }

  /// 点是否在MainRect中
  bool isInMainRect(Offset point) {
    return mMainRect.contains(point);
  }
}

class MarkerStyle {
  const MarkerStyle({
    this.isShowSellMarks = false,
    this.isShowBuyMarks = false,
    this.sellMarkColor = const Color(0xFFFF0000),
    this.buyMarkColor = const Color(0xFF00D2B4),
    this.sellMarkMargin = 16.0,
    this.buyMarkMargin = 16.0,
    this.markerSize = 16.0,
    this.markerBuyTextStyle,
    this.markerSellTextStyle,
  });

  final bool isShowSellMarks;
  final bool isShowBuyMarks;
  final Color sellMarkColor;
  final Color buyMarkColor;
  final double sellMarkMargin;
  final double buyMarkMargin;
  final double markerSize;
  final TextStyle? markerSellTextStyle;
  final TextStyle? markerBuyTextStyle;

  MarkerStyle copyWith({
    bool? isShowSellMarks,
    bool? isShowBuyMarks,
    Color? sellMarkColor,
    Color? buyMarkColor,
    double? sellMarkMargin,
    double? buyMarkMargin,
    double? markerSize,
    TextStyle? markerSellTextStyle,
    TextStyle? markerBuyTextStyle,
  }) {
    return MarkerStyle(
      isShowSellMarks: isShowSellMarks ?? this.isShowSellMarks,
      isShowBuyMarks: isShowBuyMarks ?? this.isShowBuyMarks,
      sellMarkColor: sellMarkColor ?? this.sellMarkColor,
      buyMarkColor: buyMarkColor ?? this.buyMarkColor,
      sellMarkMargin: sellMarkMargin ?? this.sellMarkMargin,
      buyMarkMargin: buyMarkMargin ?? this.buyMarkMargin,
      markerSize: markerSize ?? this.markerSize,
      markerSellTextStyle: markerSellTextStyle ?? this.markerSellTextStyle,
      markerBuyTextStyle: markerBuyTextStyle ?? this.markerBuyTextStyle,
    );
  }
}
