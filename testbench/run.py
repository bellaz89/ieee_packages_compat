"""
VUnit run script for repository testbenches.
"""

import re
from pathlib import Path
from xml.etree import ElementTree

from vunit import VUnit, VUnitCLI


def get_args(root):
    """
    Create and extract command line arguments
    """
    cli = VUnitCLI()
    cli.parser.add_argument(
        "-a",
        "--vhdl-assert-stop-level",
        default="all",
        choices=["all", "warning", "error", "failure"],
        help=('VHDL assert stop level. "all" will use all levels.'),
    )
    args = cli.parse_args()

    if args.xunit_xml is None:
        args.xunit_xml = str(root / "result.xml")

    xunit_xml_path = Path(args.xunit_xml)
    if xunit_xml_path.exists():
        xunit_xml_path.unlink()

    return args


def create_project(root, args):
    """
    Create VUnit project
    """
    prj = VUnit.from_args(args)
    prj.add_vhdl_builtins()

    ieee_compat = prj.add_library("ieee_compat", vhdl_standard="93")
    ieee_compat.add_source_files(str(root / "../ieee/*.vhdl"))
    ieee_compat.add_source_files(str(root / "*.vhdl"))

    # Work around pending VUnit dependency scanning updates
    test_fixed = ieee_compat.get_source_files("*test_fixed.vhdl")
    test_fixed2 = ieee_compat.get_source_files("*test_fixed2.vhdl")
    test_fixed3 = ieee_compat.get_source_files("*test_fixed3.vhdl")
    # test_fixed_nr = ieee_compat.get_source_files("*test_fixed_nr.vhdl")
    # test_fphdl = ieee_compat.get_source_files("*test_fphdl.vhdl")
    # test_fphdl16 = ieee_compat.get_source_files("*test_fphdl16.vhdl")
    test_fphdl64 = ieee_compat.get_source_files("*test_fphdl64.vhdl")
    test_fphdl128 = ieee_compat.get_source_files("*test_fphdl128.vhdl")
    test_fphdlbase = ieee_compat.get_source_files("*test_fphdlbase.vhdl")
    test_fpfixed = ieee_compat.get_source_files("*test_fpfixed.vhdl")
    test_fp32 = ieee_compat.get_source_files("*test_fp32.vhdl")
    # fixed_noround_pkg = ieee_compat.get_source_files("*fixed_noround_pkg.vhdl")
    # float_roundneg_pkg = ieee_compat.get_source_files("*float_roundneg_pkg.vhdl")
    # float_noround_pkg = ieee_compat.get_source_files("*float_noround_pkg.vhdl")

    fixed_pkg_conf = ieee_compat.get_source_files("*fixed_pkg_conf.vhdl")
    float_pkg_conf = ieee_compat.get_source_files("*float_pkg_conf.vhdl")
    fixed_pkg = ieee_compat.get_source_files("*fixed_pkg.vhdl")
    fixed_pkg_body = ieee_compat.get_source_files("*fixed_pkg-body.vhdl")
    float_pkg = ieee_compat.get_source_files("*float_pkg.vhdl")
    float_pkg_body = ieee_compat.get_source_files("*float_pkg-body.vhdl")
    # test_fphdl.add_dependency_on(float_roundneg_pkg)
    # test_fphdl16.add_dependency_on(float_noround_pkg)
    # test_fixed_nr.add_dependency_on(fixed_noround_pkg)

    prj.set_sim_option("vhdl_assert_stop_level", "warning")
    for testbench in ieee_compat.get_test_benches():
        for test_case in testbench.get_tests():
            if test_case.name.startswith("Expected to warn"):
                levels = ["warning", "error"]
            elif test_case.name.startswith("Expected to fail"):
                levels = ["error", "failure"]
            else:
                levels = []

            for level in levels:
                sim_options = dict(vhdl_assert_stop_level=level)
                test_case.add_config(name="stop@%s" % level, sim_options=sim_options)

    return prj


def check_report(report_file):
    """Report mismatch between test case status and expectation."""

    def expected_to_fail(test_case_name):
        if "Expected to fail" in test_case_name:
            return ("stop@warning" in test_case_name) or (
                "stop@error" in test_case_name
            )
        elif "Expected to warn" in test_case_name:
            return "stop@warning" in test_case_name
        else:
            return False

    report = ElementTree.parse(report_file)
    root = report.getroot()
    mismatch = False
    for n, test in enumerate(root.iter("testcase"), 1):
        full_name = test.attrib["classname"] + "." + test.attrib["name"]
        if test.find("skipped") is not None:
            pass
        elif test.find("failure") is not None:
            if not expected_to_fail(full_name):
                mismatch = True
                print("Wrong status for %s. Expected it to pass." % full_name)
        else:
            if expected_to_fail(full_name):
                mismatch = True
                print("Wrong status for %s. Expected it to fail." % full_name)

    if mismatch:
        raise AssertionError("Test case status mismatch")
    else:
        print("%d test cases passed and failed as expected." % n)


root = Path(__file__).parent
args = get_args(root)
prj = create_project(root, args)

try:
    prj.main()
except:
    pass

xunit_xml_path = Path(args.xunit_xml)
if xunit_xml_path.exists():
    check_report(args.xunit_xml)
