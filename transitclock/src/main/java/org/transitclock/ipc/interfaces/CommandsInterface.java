/*
 * This file is part of Transitime.org
 * 
 * Transitime.org is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License (GPL) as published by
 * the Free Software Foundation, either version 3 of the License, or
 * any later version.
 *
 * Transitime.org is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Transitime.org .  If not, see <http://www.gnu.org/licenses/>.
 */
package org.transitclock.ipc.interfaces;

import java.rmi.Remote;
import java.rmi.RemoteException;
import java.time.LocalDateTime;
import java.util.Collection;
import java.util.Date;

import org.transitclock.ipc.data.IpcAvl;

/**
 * Defines the RMI interface for sending commands or data to the server (as
 * opposed to for requesting data).
 * 
 * @author Michael
 *
 */
public interface CommandsInterface extends Remote {

	/**
	 * Sends AVL data to server.
	 * 
	 * @param avlData
	 * @return If error then contains error message string, otherwise null
	 * @throws RemoteException
	 */
	public String pushAvl(IpcAvl avlData) throws RemoteException;

	/**
	 * Sends collection of AVL data to server.
	 * 
	 * @param avlData collection of data
	 * @return If error then contains error message string, otherwise null
	 * @throws RemoteException
	 */
	public String pushAvl(Collection<IpcAvl> avlData) throws RemoteException;
	
	/*
	 * WIP This is to give a means of manually setting a vehicle unpredictable and unassigned so it will be reassigned quickly.
	 */
	public void setVehicleUnpredictable(String vehicleId) throws RemoteException;
	
	/*
	 * Cancel a trip. It should exists in current predictions.
	 * Retruns null on success
	 */
	public String cancelTrip(String tripId,LocalDateTime at) throws RemoteException;

	/*
	 * Enable a canceled trip. It should exists in current predictions.
	 * Retruns null on success
	 */
	String reenableTrip(String tripId, LocalDateTime startTripTime)  throws RemoteException;
	
	
	/*
	 * Add vehicle to Block to predictions.
	 * Returns null on success
	 */
	public String addVehicleToBlock(String vehicleId, String blockId, String tripId, Date assignmentDate, Date validFrom, Date validTo) throws RemoteException;
	
	/*
	 * Add remove vehicle to block.
	 * Returns null on success
	 */
	public String removeVehicleToBlock(long id) throws RemoteException;

	/**
	 * Add application key to db.
	 * Returns key on success or throw exception.
	 *
	 * @param applicationName name of user
	 * @param applicationUrl url of organization
	 * @param description
	 * @param email
	 * @param phone
	 */
	public String addAppKey(String applicationName, String applicationUrl,
							String email, String phone, String description) throws Exception;

	/**
	 * Add remove vehicle to block.
	 * Returns applicationName on success.
	 *
	 * @param apiKey
	 */
	public String removeAppKey(String apiKey) throws Exception;
}
