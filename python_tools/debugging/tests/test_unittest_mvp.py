# import sys
# import os
# sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../src')))

target = __import__("mvp")
max_revenue_by_any_product = target.max_revenue_by_any_product

import unittest
import numpy as np


class TestRevenue(unittest.TestCase):


    def test_max_revenue_by_any_product_valid_rect_negative(self):
        input = np.array([[0.1, 0.3], [0.2, 0.5], [0.0, -0.5]])
        output = max_revenue_by_any_product(input)
        self.assertAlmostEqual(output, 0.3, delta=1e-6)

    def test_max_revenue_by_any_product_valid_missing_values(self):
        test_cases = [
            (np.array([[-2, 2], [3, np.nan]]), 2),
            (np.array([[-2, np.nan], [3, np.nan]]), 1),
            (np.array([[np.nan, 1, -1], [-1, np.nan, 1], [1, -1, -10]]), 0),
        ]
        for input, expected in test_cases:
            with self.subTest(input=input, expected=expected):
                output = max_revenue_by_any_product(input)
                self.assertEqual(output, expected, f"Failed for input: {input}")
        
    def test_max_revenue_by_any_product_invalid_input_list(self):
        input = [1, 2, 3]
        with self.assertRaises(TypeError):
            max_revenue_by_any_product(input)  

    def test_max_revenue_by_any_product_invalid_input_empty_array(self):
        input = np.array([[],[]])
        with self.assertRaises(ValueError):
            max_revenue_by_any_product(input)  

    def test_max_revenue_by_any_product_invalid_input_1d_array(self):
        input = np.array([1, 2])
        with self.assertRaises(TypeError):
            max_revenue_by_any_product(input)  

if __name__ == "__main__":
    unittest.main()

