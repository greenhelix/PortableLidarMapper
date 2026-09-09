from setuptools import setup

package_name = 'lidar_mapper_mock'

setup(
    name=package_name,
    version='0.0.1',
    packages=[package_name],
    data_files=[
        ('share/ament_index/resource_index/packages',
            ['resource/' + package_name]),
        ('share/' + package_name, ['package.xml']),
    ],
    install_requires=['setuptools'],
    zip_safe=True,
    maintainer='dev',
    maintainer_email='dev@example.com',
    description='하드웨어 없이 /scan 토픽을 발행하는 mock 라이다 퍼블리셔',
    license='MIT',
    tests_require=['pytest'],
    entry_points={
        'console_scripts': [
            'mock_scan_publisher = lidar_mapper_mock.mock_scan_publisher:main',
        ],
    },
)
