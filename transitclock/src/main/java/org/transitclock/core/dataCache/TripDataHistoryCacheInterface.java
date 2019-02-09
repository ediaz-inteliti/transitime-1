package org.transitclock.core.dataCache;

import java.util.Date;
import java.util.List;

import org.hibernate.Session;
import org.slf4j.Logger;
import org.transitclock.db.structs.ArrivalDeparture;
import org.transitclock.ipc.data.IpcArrivalDeparture;

public interface TripDataHistoryCacheInterface {

	List<TripKey> getKeys();

	void logCache(Logger logger);

	List<IpcArrivalDeparture> getTripHistory(TripKey tripKey);

	TripKey putArrivalDeparture(ArrivalDeparture arrivalDeparture);
		
	void populateCacheFromDb(Session session, Date startDate, Date endDate);

	IpcArrivalDeparture findPreviousArrivalEvent(List<IpcArrivalDeparture> arrivalDepartures, IpcArrivalDeparture current);

	IpcArrivalDeparture findPreviousDepartureEvent(List<IpcArrivalDeparture> arrivalDepartures, IpcArrivalDeparture current);

	IpcArrivalDeparture findUpcomingDepartureEvent(List<IpcArrivalDeparture> results, IpcArrivalDeparture arrival);
}