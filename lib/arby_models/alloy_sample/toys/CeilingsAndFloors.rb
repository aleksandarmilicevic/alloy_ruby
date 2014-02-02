require 'arby_models/alloy_sample/toys/__init'

module ArbyModels::AlloySample::Toys

 # =================================================================
 # In his 1973 song, Paul Simon said "One Man's Ceiling Is Another Man's Floor".
 # Does it follow that "One Man's Floor Is Another Man's Ceiling"?
 #
 # To see why not, check the assertion BelowToo.
 #
 # Perhaps simply preventing man's own floor from being his ceiling is enough,
 # as is done in the Geometry constraint.  BelowToo' shows that there are still
 # cases where Geometry holds but the implication does not, although now
 # the smallest solution has 3 Men and 3 Platforms instead of just 2 of each.
 #
 # What if we instead prevent floors and ceilings from being shared,
 # as is done in the NoSharing constraint?  The assertion BelowToo''
 # has no counterexamples, demonstrating that the implication now
 # holds for all small examples.
 #
 # @original_author: Daniel Jackson (11/2001)
 # @modified_by:     Robert Seater (11/2004)
 # @translated_by:   Ido Efrati, Aleksandar Milicevic
 # =================================================================
 alloy :CeilingsAndFloors do

   sig Platform

   sig Man [ 
     ceiling,
     floor: Platform
   ]

   fact paulSimon { all(m: Man) | some(n: Man) { n.Above(m) } }

   pred above[m, n: Man] { 
     m.floor == n.ceiling 
   }

   assertion belowToo { all(m: Man) | some(n: Man) { m.Above(n) } }

   check :belowToo, 2 # expect sat

   pred geometry {no(m: Man) | m.floor == m.(ceiling)}

   assertion belowToo1 { 
	   if Geometry  
	      (all(m: Man) | some(n: Man) { m.Above(n) } ) 
	   end
    }

    check :belowToo1, 2  # expect 0
    check :belowToo1, 3  # expect sat

   pred noSharing {
     no(m,n: Man) { m!=n && (m.floor == n.floor || m.(ceiling) == n.(ceiling) ) }
   }

   assertion belowToo2 { 
	   if NoSharing 
	      (all(m: Man) | some(n: Man) { m.Above(n) } ) 
	   end
   }

   check :belowToo2, 6  #expect 0
   check :belowToo2, 10 #expect 0
  end
end