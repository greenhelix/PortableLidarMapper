from setuptools import setup

package_name = 'lidar_mapper_db'

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
    description='SLAM 결과를 SQLite에 세션 단위로 기록하는 노드',
    license='MIT',
    tests_require=['pytest'],
    entry_points={
        'console_scripts': [
            'session_logger_node = lidar_mapper_db.session_logger_node:main',
        ],
    },
)
