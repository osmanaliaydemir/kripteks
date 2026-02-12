using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Kripteks.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class FixExistingAuditLogs : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Mevcut kayıtlarda boş olan Severity alanını Info olarak düzelt
            migrationBuilder.Sql(
                "UPDATE AuditLogs SET Severity = 'Info' WHERE Severity = '' OR Severity IS NULL");

            // Category: Action içeriğine göre otomatik ata
            migrationBuilder.Sql(
                "UPDATE AuditLogs SET Category = 'Auth' WHERE Category = '' AND (Action LIKE '%Giriş%' OR Action LIKE '%Şifre%' OR Action LIKE '%Login%' OR Action LIKE '%Kayıt%')");

            migrationBuilder.Sql(
                "UPDATE AuditLogs SET Category = 'Bot' WHERE Category = '' AND (Action LIKE '%Bot%' OR Action LIKE '%İşlem Geçmişi%')");

            migrationBuilder.Sql(
                "UPDATE AuditLogs SET Category = 'Settings' WHERE Category = '' AND (Action LIKE '%API Anahtar%' OR Action LIKE '%Ayar%' OR Action LIKE '%Bildirim%')");

            // Kalan boş olanları System yap
            migrationBuilder.Sql(
                "UPDATE AuditLogs SET Category = 'System' WHERE Category = '' OR Category IS NULL");

            // Başarısız girişleri Warning yap
            migrationBuilder.Sql(
                "UPDATE AuditLogs SET Severity = 'Warning' WHERE Action LIKE '%Başarısız%'");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
        }
    }
}
