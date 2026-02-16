import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../src')))

target = __import__("mvp")
max_revenue_by_any_product = target.max_revenue_by_any_product

import pytest
import numpy as np

def test_max_revenue_by_any_product_valid_rect_negative():
    input = np.array([[0.1, 0.3], [0.2, 0.5], [0.0, -0.5]])
    output = max_revenue_by_any_product(input)
    assert output == pytest.approx(0.3, abs=1e-6)

@pytest.mark.parametrize("input, expected", [
    (np.array([[-2, 2], [3, np.nan]]), 2),
    (np.array([[-2, np.nan], [3, np.nan]]), 1),
    (np.array([[np.nan, 1, -1], [-1, np.nan, 1], [1, -1, -10]]), 0),
])
def test_max_revenue_by_any_product_valid_missing_values(input, expected):
    output = max_revenue_by_any_product(input)
    assert output == expected

def test_max_revenue_by_any_product_invalid_type():
    input = [[1, 2, 3], [4, 5, 6]]
    with pytest.raises(TypeError):
        max_revenue_by_any_product(input)  

def test_max_revenue_by_any_product_invalid_empty_array():
    input = np.array([[],[]])
    with pytest.raises(ValueError):
        max_revenue_by_any_product(input)  

def test_max_revenue_by_any_product_invalid_1d_array():
    input = np.array([1, 2])
    with pytest.raises(TypeError):
        max_revenue_by_any_product(input)  
