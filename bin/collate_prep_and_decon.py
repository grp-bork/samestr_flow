#!/usr/bin/env python3
import sys

def main():
	print(*sys.argv[1:], sep="\n")


if __name__ == "__main__":
	main()