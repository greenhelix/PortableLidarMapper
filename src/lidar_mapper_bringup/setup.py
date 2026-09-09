import os
from glob import glob
from setuptools import setup

package_name = 'lidar_mapper_bringup'

setup(
    name=package_name,
    version='0.0.1',
    packages=[],
    data_files=[
        ('share/ament_index/resource_index/packages',
            ['resource/' + package_name]),
        ('share/' + package_name, ['package.xml']),
        (os.path.join('share', package_name, 'launch'), glob('launch/*.launch.py')),
    ],
    install_requires=['setuptools'],
    zip_safe=True,
    maintainer='dev',
    maintainer_email='dev@example.com',
    description='전체 파이프라인(mock/real 라이다 + slam_toolbox + rosbridge) 통합 실행용',
    license='MIT',
)
