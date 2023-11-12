import time

matrix = [
    [False for _ in range(10)]
    for _ in range(10)
]

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

offset = False

while len(positions) != 0:
    x, y = positions.pop()
    try:
        matrix[x][y] = True
    except IndexError:
        continue
    print_matrix(matrix)
    if x >= 9:
        offset = not offset
        positions.append((0, y))
    else:
        if offset:
            positions.append((x, y + 2))
        else:
            positions.append((x, y + 3))
