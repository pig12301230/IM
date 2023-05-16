//
//  Theme.swift
//  ChatRoom
//
//  Created by saffi_peng on 2021/4/23.
//

import Foundation
import SwiftTheme

enum Theme: ThemeColorPicker {

    case c_01_primary_0_500 = "c_01_primary_primary_0_500"
    case c_01_primary_400 = "c_01_primary_primary_400"
    case c_01_primary_300 = "c_01_primary_primary_300"
    case c_01_primary_200 = "c_01_primary_primary_200"
    case c_01_primary_100 = "c_01_primary_primary_100"
    case c_01_primary_600 = "c_01_primary_primary_600"
    case c_01_primary_700 = "c_01_primary_primary_700"
    case c_01_primary_800 = "c_01_primary_primary_800"

    case c_02_secondary_0_500 = "c_02_secondary_secondary_0_500"
    case c_02_secondary_400 = "c_02_secondary_secondary_400"
    case c_02_secondary_300 = "c_02_secondary_secondary_300"
    case c_02_secondary_200 = "c_02_secondary_secondary_200"
    case c_02_secondary_100 = "c_02_secondary_secondary_100"
    case c_02_secondary_600 = "c_02_secondary_secondary_600"
    case c_02_secondary_700 = "c_02_secondary_secondary_700"
    case c_02_secondary_800 = "c_02_secondary_secondary_800"

    case c_09_white = "c_09_white_white"
    case c_08_black = "c_08_black_black"
    case transparent = "transparent"

    case c_03_tertiary_0_500 = "c_03_tertiary_tertiary_0_500"
    case c_03_tertiary_100 = "c_03_tertiary_tertiary_100"
    case c_03_tertiary_200 = "c_03_tertiary_tertiary_200"
    case c_03_tertiary_300 = "c_03_tertiary_tertiary_300"
    case c_03_tertiary_400 = "c_03_tertiary_tertiary_400"
    case c_03_tertiary_600 = "c_03_tertiary_tertiary_600"
    case c_03_tertiary_700 = "c_03_tertiary_tertiary_700"
    case c_03_tertiary_800 = "c_03_tertiary_tertiary_800"

    case c_04_success_100 = "c_04_success_success_100"
    case c_04_success_200 = "c_04_success_success_200"
    case c_04_success_300 = "c_04_success_success_300"
    case c_04_success_400 = "c_04_success_success_400"
    case c_04_success_0_500 = "c_04_success_success_0_500"
    case c_04_success_600 = "c_04_success_success_600"
    case c_04_success_700 = "c_04_success_success_700"
    case c_04_success_800 = "c_04_success_success_800"

    case c_05_warning_100 = "c_05_warning_warning_100"
    case c_05_warning_200 = "c_05_warning_warning_200"
    case c_05_warning_300 = "c_05_warning_warning_300"
    case c_05_warning_400 = "c_05_warning_warning_400"
    case c_05_warning_0_500 = "c_05_warning_warning_0_500"
    case c_05_warning_600 = "c_05_warning_warning_600"
    case c_05_warning_700 = "c_05_warning_warning_700"
    case c_05_warning_800 = "c_05_warning_warning_800"

    case c_06_danger_100 = "c_06_danger_danger_100"
    case c_06_danger_200 = "c_06_danger_danger_200"
    case c_06_danger_300 = "c_06_danger_danger_300"
    case c_06_danger_400 = "c_06_danger_danger_400"
    case c_06_danger_0_500 = "c_06_danger_danger_0_500"
    case c_06_danger_600 = "c_06_danger_danger_600"
    case c_06_danger_700 = "c_06_danger_danger_700"
    case c_06_danger_800 = "c_06_danger_danger_800"

    case c_07_neutral_100 = "c_07_neutral_neutral_100"
    case c_07_neutral_0 = "c_07_neutral_neutral_0"
    case c_07_neutral_50 = "c_07_neutral_neutral_50"
    case c_07_neutral_200 = "c_07_neutral_neutral_200"
    case c_07_neutral_300 = "c_07_neutral_neutral_300"
    case c_07_neutral_400 = "c_07_neutral_neutral_400"
    case c_07_neutral_500 = "c_07_neutral_neutral_500"
    case c_07_neutral_600 = "c_07_neutral_neutral_600"
    case c_07_neutral_700 = "c_07_neutral_neutral_700"
    case c_07_neutral_800 = "c_07_neutral_neutral_800"
    case c_07_neutral_900 = "c_07_neutral_neutral_900"
    case c_07_neutral_900_10 = "c_07_neutral_neutral_900_10"

    case c_08_black_75 = "c_08_black_black_75"
    case c_08_black_66 = "c_08_black_black_66"
    case c_08_black_50 = "c_08_black_black_50"
    case c_08_black_30 = "c_08_black_black_30"
    case c_08_black_33 = "c_08_black_black_33"
    case c_08_black_25 = "c_08_black_black_25"
    case c_08_black_10 = "c_08_black_black_10"
    case c_08_black_05 = "c_08_black_black_05"

    case c_09_white_75 = "c_09_white_white_75"
    case c_09_white_66 = "c_09_white_white_66"
    case c_09_white_50 = "c_09_white_white_50"
    case c_09_white_33 = "c_09_white_white_33"
    case c_09_white_25 = "c_09_white_white_25"
    case c_09_white_10 = "c_09_white_white_10"
    case c_09_white_5 = "c_09_white_white_5"

    case c_10_grand_1 = "c_10_grand_grand_1"
    case c_10_grand_2 = "c_10_grand_grand_2"
    case c_10_grand_3 = "c_10_grand_grand_3"
    case c_10_grand_4 = "c_10_grand_grand_4"
}

extension ThemeColorPicker {
    func toColor() -> UIColor {
        return self.value() as? UIColor ?? .clear
    }

    func toCGColor() -> CGColor {
        return (self.value() as? UIColor)?.cgColor ?? UIColor.clear.cgColor
    }
}
