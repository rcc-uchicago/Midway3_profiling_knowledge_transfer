import numpy as np


def max_revenue_by_any_product(report: np.ndarray) -> float:
    """Report is a 2D array with rows representing time, columns are products, entries are revenues"""
    if not isinstance(report, np.ndarray):
        raise TypeError("Input must be a numpy array")
    if report.ndim != 2:
        raise TypeError("Input must be a 2D numpy array")
    # if report.shape[1] == 0:
    #     raise ValueError("Input must have at least one column)")
    return np.max(np.nansum(report, axis=0))


if __name__ == "__main__":
    scenarios = {
        "1": [1, 2, 3],
        "2": np.array([1, 2]),
        "3": np.array([[2, 4], [1, 6]]),
        "4": np.array([[2, 4], [1, np.nan]]),
        "5": np.array([[], []]),
    }

    print("Select a scenario to run:")
    for key, value in scenarios.items():
        print(f"{key}: {value}")

    choice = input("Enter the scenario number: ")

    if choice in scenarios:
        report = scenarios[choice]
        try:
            print("Selected report:", report)
            print("Max revenue:", max_revenue_by_any_product(report))
        except Exception as e:
            print("Error:", e)
    else:
        print("Invalid choice. Please select a valid scenario number.")
