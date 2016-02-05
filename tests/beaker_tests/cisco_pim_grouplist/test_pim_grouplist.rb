###############################################################################
# Copyright (c) 2015 Cisco and/or its affiliates.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
###############################################################################
# TestCase Name:
# -------------
# test-pimrpaddress.rb
#
# TestCase Prerequisites:
# -----------------------
# This is a Puppet PIM rp address resource testcase for Puppet Agent on
# Nexus devices.
# The test case assumes the following prerequisites are already satisfied:
#   - Host configuration file contains agent and master information.
#   - SSH is enabled on the N9K Agent.
#   - Puppet master/server is started.
#   - Puppet agent certificate has been signed on the Puppet master/server.
#
# TestCase:
# ---------
# This PIM rp address resource test verifies default values for all properties.
#
# The following exit_codes are validated for Puppet, Vegas shell and
# Bash shell commands.
#
# Vegas and Bash Shell Commands:
# 0   - successful command execution
# > 0 - failed command execution.
#
# Puppet Commands:
# 0 - no changes have occurred
# 1 - errors have occurred,
# 2 - changes have occurred
# 4 - failures have occurred and
# 6 - changes and failures have occurred.
#
# NOTE: 0 is the default exit_code checked in Beaker::DSL::Helpers::on() method.
#
# The test cases use RegExp pattern matching on stdout or output IO
# instance attributes to verify resource properties.
#
###############################################################################

require File.expand_path('../../lib/utilitylib.rb', __FILE__)

# -----------------------------
# Common settings and variables
# -----------------------------
testheader = 'Resource cisco_pim_grouplist'

# Define PUPPETMASTER_MANIFESTPATH.
# UtilityLib.set_manifest_path(master, self)

# The 'tests' hash is used to define all of the test data values and expected
# results. It is also used to pass optional flags to the test methods when
# necessary.

# 'tests' hash
# Top-level keys set by caller:
# tests[:master] - the master object
# tests[:agent] - the agent object
# tests[:show_cmd] - the common show command to use for test_show_run
#
tests = {
  master:   master,
  agent:    agent,
  show_cmd: 'show run pim all',
}
# tests[id] keys set by caller and used by test_harness_common:
#
# tests[id] keys set by caller:
# tests[id][:desc] - a string to use with logs & debugs
# tests[id][:manifest] - the complete manifest, as used by test_harness_common
# tests[id][:resource] - a hash of expected states, used by test_resource
# tests[id][:resource_cmd] - 'puppet resource' command to use with test_resource
# tests[id][:show_pattern] - array of regexp patterns to use with test_show_cmd
# tests[id][:ensure] - (Optional) set to :present or :absent before calling
# tests[id][:code] - (Optional) override the default exit code in some tests.
#
# These keys are local use only and not used by test_harness_common:
#
# tests[id][:manifest_props] - This is essentially a master list of properties
#   that permits re-use of the properties for both :present and :absent testing
#   without destroying the list
# tests[id][:resource_props] - This is essentially a master hash of properties
#   that permits re-use of the properties for both :present and :absent testing
#   without destroying the hash
# tests[id][:title_pattern] - (Optional) defines the manifest title.
#   Can be used with :pim for mixed title/pim testing. If mixing, :pim values will
#   be merged with title values and override any duplicates. If omitted,
#   :title_pattern will be set to 'id'.
#
tests['title_patterns'] = {
  manifest_props: '',
  resource_props: { 'ensure' => 'present' },
}
#################################################################
# HELPER FUNCTIONS
#################################################################
# Full command string for puppet resource with neighbor AF
def puppet_resource_cmd(pim_group)
  cmd = PUPPET_BINPATH + \
        "resource cisco_pim_grouplist '#{pim_group.values.join(' ')}'"
  get_namespace_cmd(agent, cmd, options)
end

def build_manifest_cisco_pim_grouplist(tests, id)
  manifest = prop_hash_to_manifest(tests[id][:pim_group])
  if tests[id][:ensure] == :absent
    state = 'ensure => absent,'
    tests[id][:resource] = { 'ensure' => 'absent' }
  else
    state = 'ensure => present,'
    tests[id][:resource] = tests[id][:resource_props]
  end

  tests[id][:title_pattern] = id if tests[id][:title_pattern].nil?
  logger.debug("build_manifest_cisco_pim_grouplist :: title_pattern:\n" +
               tests[id][:title_pattern])
  tests[id][:manifest] = "cat <<EOF >#{PUPPETMASTER_MANIFESTPATH}
  node 'default' {
    cisco_pim_grouplist { '#{tests[id][:title_pattern]}':
      #{state}
      #{manifest}
    }
  }
EOF"
end

def test_harness_cisco_pim_grouplist(tests, id)
  pim_group = pim_group_title_pattern_munge(tests, id)
  logger.info("\n--------\nTest Case Pim ID: #{pim_group}")

  tests[id][:ensure] = :present if tests[id][:ensure].nil?
  tests[id][:resource_cmd] = puppet_resource_cmd(pim_group)

  # Build the manifest for this test
  build_manifest_cisco_pim_grouplist(tests, id)
  test_harness_common(tests, id)
  tests[id][:ensure] = nil
end

#################################################################
# TEST CASE EXECUTION
#################################################################
test_name "TestCase :: #{testheader}" do
  # -------------------------------------------------------------------
  logger.info("\n#{'-' * 60}\nSection 1. Title Pattern Testing")
  resource_absent_cleanup(agent, 'cisco_pim_grouplist',
                          'Setup switch for cisco_pim_grouplist provider test')
  # -----------------------------------
  id = 'title_patterns'
  tests[id][:desc] = '3.1 Title Patterns'
  tests[id][:title_pattern] = 'newyork'
  tests[id][:pim_group] = { afi: 'ipv4', vrf: 'red',
          rp_addr: '22.22.22.22', group: '224.0.0.0/8' }
  test_harness_cisco_pim_grouplist(tests, id)

  # -----------------------------------
  tests[id][:desc] = '3.2 Title Patterns'
  tests[id][:title_pattern] = 'ipv4'
  tests[id][:pim_group] = { vrf: 'red', rp_addr: '33.33.33.33',
                            group: '225.0.0.0/8' }
  test_harness_cisco_pim_grouplist(tests, id)

  # -----------------------------------
  tests[id][:desc] = '3.3 Title Patterns'
  tests[id][:title_pattern] = 'ipv4 red'
  tests[id][:pim_group] = { rp_addr: '44.44.44.44',
                            group:   '226.0.0.0/8' }
  test_harness_cisco_pim_grouplist(tests, id)

  # -----------------------------------
  tests[id][:desc] = '3.4 Title Patterns'
  tests[id][:title_pattern] = 'ipv4 default 55.55.55.55 227.0.0.0/8'
  tests[id][:pim_group] = {}
  test_harness_cisco_pim_grouplist(tests, id)
end

logger.info("TestCase :: #{testheader} :: End")