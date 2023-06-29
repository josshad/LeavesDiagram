//  Created by Danila Gusev on 09/10/22.
//  Copyright © 2022 josshad. All rights reserved.

import Foundation

let CGFloat2PI = 2 * CGFloat.pi
let CGFloatPI_2 = CGFloat.pi / 2

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
    if CGFloatCompare(val, CGFloat2PI) == .orderedAscending {
        return val
    }

    return val - floor(val / CGFloat2PI) * CGFloat2PI;
}
