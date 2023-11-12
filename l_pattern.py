import time

matrix = [
    [False for _ in range(10)]
    for _ in range(10)
]

def knight(x: int, y: int):
    return [
        (x + 1, y + 2),
        (x + 2, y + 1),
        (x + 2, y - 1),
        (x + 1, y - 2),
        (x - 1, y - 2),
        (x - 2, y - 1),
        (x - 2, y + 1),
        (x - 1, y + 2),
    ]

def jump(matrix, x: int, y: int):
    positions = []
    for (ox, oy) in knight(x, y):
        if ox < 0 or oy < 0:
            continue
        try:
            if matrix[ox][oy]:
                continue
            matrix[ox][oy] = True
            positions.append((ox, oy))
        except IndexError:
            pass
    return matrix, positions

def print_matrix(matrix):
    print()
    print("#" * 10)
    res = {
        True: "X",
        False: " "
    }
    for row in matrix:
        print("".join([res[state] for state in row]))


positions = [(0, 0)]
matrix[0][0] = True

while len(positions) != 0:
    x, y = positions.pop()
    matrix, new_positions = jump(matrix, x, y)
    print_matrix(matrix)
    positions += new_positions
    time.sleep(0.5)

