import Foundation

func CGFloatCompare(_ l: CGFloat, _ r: CGFloat, _ eps: CGFloat) -> ComparisonResult {
    if abs(l - r) <= eps {
        return .orderedSame
    } else if l < r {
        return .orderedAscending
    } else {
        return .orderedDescending
    }
}

func CGFloatCompare(_ l: CGFloat, _ r: CGFloat) -> ComparisonResult {
    CGFloatCompare(l, r, CGFloat.ulpOfOne * 16)
}

func CGFloatEqual(_ l: CGFloat, _ r: CGFloat) -> Bool {
    CGFloatCompare(l, r) == .orderedSame
}

func CGFloatNormalizedAngle(_ val: CGFloat) -> CGFloat {
    let pix2 = CGFloat.pi * 2
    if CGFloatCompare(val, pix2) == .orderedAscending {
        return val
    }

    return val - floor(val / pix2) * pix2;
}
