package org.transitclock.api.data;

import org.transitclock.db.webstructs.ApiKey;

import javax.xml.bind.annotation.XmlAttribute;
import javax.xml.bind.annotation.XmlRootElement;


/**
 * Describes a key
 *
 * @author TsimurSh
 */
@XmlRootElement(name = "key")
public class ApiAppKey {

    @XmlAttribute
    private String name;

    @XmlAttribute
    private String applicationKey;

    @XmlAttribute
    private String url;

    @XmlAttribute
    private String description;

    @XmlAttribute
    private String phone;

    @XmlAttribute
    private String email;

    /********************** Member Functions **************************/

    /**
     * Need a no-arg constructor for Jersey. Otherwise get really obtuse
     * "MessageBodyWriter not found for media type=application/json" exception.
     */
    protected ApiAppKey() {
    }

    public ApiAppKey(ApiKey apiKey) {
        this.name = apiKey.getApplicationName();
        this.applicationKey = apiKey.getKey();
        this.url = apiKey.getApplicationUrl();
        this.description = apiKey.getDescription();
        this.email = apiKey.getEmail();
        this.phone = apiKey.getPhone();
    }
}
