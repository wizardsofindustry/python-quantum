#!/usr/bin/env python3
from setuptools import find_packages
from setuptools import setup


setup(
    name='quantum',
    version=str.strip(open('VERSION').read()),
    packages=find_packages()
)

# pylint: skip-file
