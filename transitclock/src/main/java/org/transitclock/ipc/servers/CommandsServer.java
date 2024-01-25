package org.transitclock.ipc.servers;

import java.rmi.RemoteException;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.Collection;
import java.util.Date;

import org.hibernate.Session;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.transitclock.avl.AvlExecutor;
import org.transitclock.core.AvlProcessor;
import org.transitclock.core.TemporalMatch;
import org.transitclock.core.VehicleState;
import org.transitclock.core.dataCache.PredictionDataCache;
import org.transitclock.core.dataCache.VehicleDataCache;
import org.transitclock.core.dataCache.VehicleStateManager;
import org.transitclock.db.hibernate.HibernateUtils;
import org.transitclock.db.structs.AvlReport;
import org.transitclock.db.structs.VehicleEvent;
import org.transitclock.db.structs.VehicleToBlockConfig;
import org.transitclock.db.webstructs.ApiKey;
import org.transitclock.db.webstructs.ApiKeyManager;
import org.transitclock.ipc.data.IpcAvl;
import org.transitclock.ipc.data.IpcVehicleComplete;
import org.transitclock.ipc.interfaces.CommandsInterface;
import org.transitclock.ipc.rmi.AbstractServer;

public class CommandsServer extends AbstractServer implements CommandsInterface {

    // Should only be accessed as singleton class
    private static CommandsServer singleton;

    private static final Logger logger =
            LoggerFactory.getLogger(CommandsServer.class);

    /********************** Member Functions **************************/

    /**
     * Starts up the CommandsServer so that RMI calls can be used to control the
     * server. This will automatically cause the object to continue to run and
     * serve requests.
     *
     * @param agencyId
     * @return the singleton CommandsServer object. Usually does not need to
     * used since the server will be fully running.
     */
    public static CommandsServer start(String agencyId) {
        if (singleton == null) {
            singleton = new CommandsServer(agencyId);
        }

        if (!singleton.getAgencyId().equals(agencyId)) {
            logger.error("Tried calling CommandsServer.start() for " +
                            "agencyId={} but the singleton was created for agencyId={}",
                    agencyId, singleton.getAgencyId());
            return null;
        }

        return singleton;
    }

    /**
     * Constructor. Made private so that can only be instantiated by
     * get(). Doesn't actually do anything since all the work is done in
     * the superclass constructor.
     *
     * @param agencyId for registering this object with the rmiregistry
     */
    private CommandsServer(String agencyId) {
        super(agencyId, CommandsInterface.class.getSimpleName());
    }

    /**
     * Called on server side via RMI when AVL data is to be processed
     *
     * @param avlData AVL data sent to server
     * @return Null if OK, otherwise an error message
     */
    @Override
    public String pushAvl(IpcAvl avlData) throws RemoteException {
        // Use AvlExecutor to actually process the data using a thread executor
        AvlReport avlReport = new AvlReport(avlData);
        logger.debug("Processing AVL report {}", avlReport);
        AvlExecutor.getInstance().processAvlReport(avlReport);

        // Return that was successful
        return null;
    }

    /**
     * Called on server side via RMI when AVL data is to be processed
     *
     * @param avlDataCollection AVL data sent to server
     * @return Null if OK, otherwise an error message
     */
    @Override
    public String pushAvl(Collection<IpcAvl> avlDataCollection) throws RemoteException {
        for (IpcAvl avlData : avlDataCollection) {
            // Use AvlExecutor to actually process the data using a thread executor
            AvlReport avlReport = new AvlReport(avlData);
            logger.debug("Processing AVL report {}", avlReport);
            AvlExecutor.getInstance().processAvlReport(avlReport);
        }

        // Return that was successful
        return null;
    }

    @Override
    public void setVehicleUnpredictable(String vehicleId) throws RemoteException {

        VehicleState vehicleState = VehicleStateManager.getInstance()
                .getVehicleState(vehicleId);

        // Create a VehicleEvent to record what happened
        AvlReport avlReport = vehicleState.getAvlReport();
        TemporalMatch lastMatch = vehicleState.getMatch();
        boolean wasPredictable = vehicleState.isPredictable();

        String vehicleEvent = "Command called to make vehicleId unpredicable. ";
        String eventDescription = "Command called to make vehicleId unpredicable. ";
        ;
        VehicleEvent.create(avlReport, lastMatch, vehicleEvent,
                eventDescription, false, // predictable
                wasPredictable, // becameUnpredictable
                null); // supervisor

        // Update the state of the vehicle
        vehicleState.setMatch(null);

        // Remove the predictions that were generated by the vehicle
        PredictionDataCache.getInstance().removePredictions(vehicleState);

        // Update VehicleDataCache with the new state for the vehicle
        VehicleDataCache.getInstance().updateVehicle(vehicleState);

    }

    private VehicleState getVehicleStateForTrip(String tripId, LocalDateTime _startTripTime) {
        /**
         * The startTripTime parameter should not be null if noSchedule
         */
        long startTripTime = 0;
        if (_startTripTime != null)
            startTripTime = _startTripTime.atZone(ZoneId.systemDefault()).toEpochSecond() * 1000L;
        /**
         * Get the vehicle assosiated to the tripId.
         * Is it  possible to have more than 1 bus with the same tripId??
         */
        Collection<IpcVehicleComplete> ipcVehicleCompletList = VehicleDataCache.getInstance().getVehiclesIncludingSchedBasedOnes();
        VehicleState vehicleState = null;
        for (IpcVehicleComplete _ipcVehicle : ipcVehicleCompletList) {


            if (_ipcVehicle.getTripId() != null && _ipcVehicle.getTripId().compareTo(tripId) == 0) {
                VehicleState _vehicleState = VehicleStateManager.getInstance()
                        .getVehicleState(_ipcVehicle.getId());
                boolean noSchedule = _vehicleState.getTrip().isNoSchedule();
                if (!noSchedule) {
                    vehicleState = _vehicleState;
                    break;
                } else if (noSchedule && _ipcVehicle.getTripStartEpochTime() == startTripTime) {
                    vehicleState = _vehicleState;
                    break;
                }

            }
        }
        return vehicleState;
    }

    @Override
    public String cancelTrip(String tripId, LocalDateTime startTripTime) {

        //String vehicleId=	"block_" + blockId + "_schedBasedVehicle";
        VehicleState vehicleState = this.getVehicleStateForTrip(tripId, startTripTime);
        if (vehicleState == null)
            return "TripId id is not currently available";

        AvlReport avlReport = vehicleState.getAvlReport();
        if (avlReport != null) {
            vehicleState.setCanceled(true);
            VehicleDataCache.getInstance().updateVehicle(vehicleState);
            AvlProcessor.getInstance().processAvlReport(avlReport);
            return null;
        } else
            return "vehicle with this trip id does not have avl report";


    }

    @Override
    public String reenableTrip(String tripId, LocalDateTime startTripTime) {

        //String vehicleId=	"block_" + blockId + "_schedBasedVehicle";
        VehicleState vehicleState = this.getVehicleStateForTrip(tripId, startTripTime);
        if (vehicleState == null)
            return "TripId id is not currently available";
        AvlReport avlReport = vehicleState.getAvlReport();
        if (avlReport != null) {
            vehicleState.setCanceled(false);
            VehicleDataCache.getInstance().updateVehicle(vehicleState);
            AvlProcessor.getInstance().processAvlReport(avlReport);
            return null;
        } else
            return "vehicle with this trip id does not have avl report";
    }

    @Override
    public String addVehicleToBlock(String vehicleId, String blockId, String tripId, Date assignmentDate, Date validFrom, Date validTo) {
        VehicleToBlockConfig.create(vehicleId, blockId, tripId, assignmentDate, validFrom, validTo);
        return null;
    }

    @Override
    public String removeVehicleToBlock(long id) {
        Session session = HibernateUtils.getSession();
        try {
            VehicleToBlockConfig.deleteVehicleToBlockConfig(id, session);
            session.close();
        } catch (Exception ex) {
            session.close();
        }
        return null;
    }

    @Override
    public String addAppKey(String applicationName, String applicationUrl,
                            String email, String phone, String description) throws RemoteException, RuntimeException {
        try {
            ApiKey key = ApiKeyManager.getInstance()
                    .generateApiKey(applicationName, applicationUrl, email, phone, description);
            logger.info("Successfully created and added application key for {} to database. ", key.getApplicationName());
            return key.getKey();
        } catch (Exception exception) {
            logger.error(exception.getMessage());
            throw exception;
        }
    }

    @Override
    public String removeAppKey(String apiKey) throws RemoteException, RuntimeException {

        try {
            String result = ApiKeyManager.getInstance().deleteKey(apiKey);
            logger.info("Successfully deleted key for {} from database. ", apiKey);
            return result;

        } catch (Exception exception) {
            logger.error(exception.getMessage());
            throw exception;
        }
    }
}
