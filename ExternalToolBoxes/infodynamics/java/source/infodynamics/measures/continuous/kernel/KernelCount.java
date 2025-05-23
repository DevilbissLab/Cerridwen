/*
 *  Java Information Dynamics Toolkit (JIDT)
 *  Copyright (C) 2012, Joseph T. Lizier
 *  
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *  
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *  
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

package infodynamics.measures.continuous.kernel;

/**
 * Structure to hold a kernel count, the total count it was taken from,
 *  and an array of booleans indicating which time points got counted.
 * 
 * @author Joseph Lizier (<a href="joseph.lizier at gmail.com">email</a>,
 * <a href="http://lizier.me/joseph/">www</a>)
 */
public class KernelCount {
	public int count;
	public int totalObservationsForCount;
	public boolean[] isCorrelatedWithArgument;
	
	public KernelCount(int count, int totalObservationsForCount, boolean[] isCorrelatedWithArgument) {
		this.count = count;
		this.totalObservationsForCount = totalObservationsForCount;
		this.isCorrelatedWithArgument = isCorrelatedWithArgument;
	}
	
	public KernelCount(int count, int totalObservationsForCount) {
		this(count, totalObservationsForCount, null);
	}
}