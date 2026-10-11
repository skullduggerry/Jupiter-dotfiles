import QtQuick
import "../../.config/quickshell/services"

// The Nextcloud address the calendar is set up with ("Calendar" in
// PROJECT_STRUCTURE.md): the app password goes out as HTTP Basic auth, so
// only https, or http that cannot leave the machine.
TestCase {
    function test_anyPageOfTheWebUi() {
        compare(CalendarService.baseAddress(" https://cloud.example.org/index.php/apps/calendar/dayGridMonth "), "https://cloud.example.org");
        compare(CalendarService.baseAddress("https://example.org/nextcloud/remote.php/dav/"), "https://example.org/nextcloud");
        compare(CalendarService.baseAddress("https://cloud.example.org///"), "https://cloud.example.org");
    }

    function test_onlyHttpsOrLoopback() {
        compare(CalendarService.addressProblem("https://cloud.example.org"), "");
        compare(CalendarService.addressProblem("http://localhost:8080"), "");
        compare(CalendarService.addressProblem("http://127.0.0.1"), "");
        verify(CalendarService.addressProblem("http://cloud.example.org") !== "");
        verify(CalendarService.addressProblem("http://localhost.example.org") !== "");
        verify(CalendarService.addressProblem("") !== "");
    }
}
