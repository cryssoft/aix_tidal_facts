#
#  FACT(S):     aix_tidal
#
#  PURPOSE:     This custom fact returns a complex fact hash that can be used
#		to fill in the AIX Tidal web page in the dashboard.
#
#  RETURNS:     (hash)
#
#  AUTHOR:      Chris Petersen, Crystallized Software
#
#  DATE:        February 9, 2021
#
#  NOTES:       Myriad names and acronyms are trademarked or copyrighted by IBM
#               including but not limited to IBM, PowerHA, AIX, RSCT (Reliable,
#               Scalable Cluster Technology), and CAA (Cluster-Aware AIX).  All
#               rights to such names and acronyms belong with their owner.
#
#-------------------------------------------------------------------------------
#
#  LAST MOD:    June 4, 2022
#
#  MODIFICATION HISTORY:
#
#  2022/06/04 - cp - Need to modify the package logic to pick up just the "usr
#		part" of the package because of the way we changed the package.
#
#-------------------------------------------------------------------------------
#
Facter.add(:aix_tidal) do
    #  This only applies to the AIX operating system
    confine :osfamily => 'AIX'

    #  Define an somewhat empty hash for our output
    l_aixTIDAL                     = {}
    l_aixTIDAL['agent_name']       = ''
    l_aixTIDAL['agent_tz']         = ''
    l_aixTIDAL['java']             = {}
    l_aixTIDAL['java']['version']  = ''
    l_aixTIDAL['java']['heap_min'] = ''
    l_aixTIDAL['java']['heap_max'] = ''
    l_aixTIDAL['packaged']         = false
    l_aixTIDAL['running']          = false
    l_aixTIDAL['user']             = ''
    l_aixTIDAL['version']          = ''

    #  Do the work
    setcode do
        #  Run the command to look through the process list for the Tidal daemon
        l_lines = Facter::Util::Resolution.exec('/bin/ps -ef 2>/dev/null')

        #  Loop over the lines that were returned
        l_lines && l_lines.split("\n").each do |l_oneLine|
            #  Skip comments and blanks
            l_oneLine = l_oneLine.strip()
            #  Look for a telltale and rip apart that line
            if (l_oneLine =~ /TAgent.jar/)
                #  Split on any combination of whitespace
                l_list = l_oneLine.split()
                #  Stash stuff
                l_aixTIDAL['user']=l_list[0]
                l_list.each do |l_psItem|
                    #
                    l_piecesSlash=l_psItem.split('/')
                    if (l_piecesSlash[-1] == 'java')
                        l_aixTIDAL['java']['version'] = l_piecesSlash[2]
                    end
                    if (l_psItem[0..3] == '-Xms')
                        l_aixTIDAL['java']['heap_min'] = l_psItem[4..-1]
                    end
                    if (l_psItem[0..3] == '-Xmx')
                        l_aixTIDAL['java']['heap_max'] = l_psItem[4..-1]
                    end
                    #
                    l_piecesEqual=l_psItem.split('=')
                    if (l_piecesEqual[0] == 'agent')
                        l_aixTIDAL['agent_name'] = l_piecesEqual[1]
                    end
                    if (l_piecesEqual[0] == '-DAGENTTZ')
                        l_aixTIDAL['agent_tz'] = l_piecesEqual[1]
                    end
                end

                #  If we found this in "ps" output, then we're definitly running
                l_aixTIDAL['running'] = true
            end
        end


        #  Run the command to list the history of the bos.mp64 package
        l_lines = Facter::Util::Resolution.exec('/bin/lslpp -hc tidal.rte 2>/dev/null')

        #  Loop over the lines that were returned
        l_lines && l_lines.split("\n").each do |l_oneLine|
            #  Skip comments and blanks
            l_oneLine = l_oneLine.strip()
            next if l_oneLine =~ /^#/ or l_oneLine =~ /^$/

            #  Split regular lines for the "usr part", and stash the relevant fields
            if (l_oneLine =~ /\/usr\//)
                l_list = l_oneLine.split(':')
                l_aixTIDAL['version']  = l_list[2]
                l_aixTIDAL['packaged'] = true
            end
        end

        #  Implicitly return the contents of the variable
        l_aixTIDAL
    end
end
