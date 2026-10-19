# SPDX-License-Identifier: BSD-3-Clause
"""Validate the checked-in colored Go2-W description and meshes."""

import os
from pathlib import Path
import xml.etree.ElementTree as ET

import pytest


SOURCE = Path(os.environ['GO2W_DESCRIPTION_SOURCE'])
NS = {'c': 'http://www.collada.org/2005/11/COLLADASchema'}


@pytest.fixture
def robot():
    return ET.parse(SOURCE / 'urdf/go2w_description.urdf').getroot()


def test_urdf_is_self_contained_and_colored(robot):
    movable = [joint for joint in robot.findall('joint')
               if joint.get('type') != 'fixed']
    assert len(movable) == 16

    meshes = robot.findall('.//visual/geometry/mesh')
    assert meshes
    assert all(mesh.get('filename').startswith('package://go2w_description/dae/')
               for mesh in meshes)

    body_materials = robot.findall(".//visual/material[@name='go2w_body']")
    assert len(body_materials) == 4


@pytest.mark.parametrize('filename', ['left_wheel.dae', 'right_wheel.dae'])
def test_wheel_meshes_have_baked_tire_and_hub_materials(filename):
    root = ET.parse(SOURCE / 'dae' / filename).getroot()
    effects = {effect.get('id') for effect in root.findall(
        'c:library_effects/c:effect', NS)}
    materials = {material.get('id') for material in root.findall(
        'c:library_materials/c:material', NS)}
    primitives = root.findall('.//c:geometry/c:mesh/c:triangles', NS)

    assert {'go2w_tire_effect', 'go2w_hub_effect'} <= effects
    assert {'go2w_tire', 'go2w_hub'} <= materials
    assert {primitive.get('material') for primitive in primitives} == {
        'go2w_tire', 'go2w_hub'}


def test_all_visual_mesh_files_exist(robot):
    for mesh in robot.findall('.//visual/geometry/mesh'):
        relative = mesh.get('filename').removeprefix(
            'package://go2w_description/')
        assert (SOURCE / relative).is_file()
