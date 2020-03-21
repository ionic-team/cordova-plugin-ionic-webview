# FAQ

## Whitespace above and below content / Content not filling 100% of the screen
Tags: ios 11, ios 12, ios 13  

**1) You should ensure `viewport-fit=cover` for your html page**  
In html head include `<meta name="viewport" content="initial-scale=1.0, viewport-fit=cover">`

> About:  
For iOS11+ this results in the scrollView automatically setting the `ContentInsetAdjustmentBehavior` to `UIScrollViewContentInsetAdjustmentNever` which eliminates the safeInset, (the whitespace), that is applied natively.  
The safeInset is used to indicate which parts of the screen are partially obscurred (like the little black dip at the top border of the iPhone X).  So if you want to be able to conditionally avoid placing content in that area you can use css and the iOS provided css env() variable [safe-area-inset-<top/bottom/left/rigth>](https://webkit.org/blog/7929/designing-websites-for-iphone-x/).

**2) Apply css style `height:100vh;` to at least the `<html>`, `<body>`, or container element in body.**  
If this doesn't appear to be working, you can read through [here](https://github.com/apache/cordova-plugin-wkwebview-engine/issues/108) for additional tips on the styling requirements.
