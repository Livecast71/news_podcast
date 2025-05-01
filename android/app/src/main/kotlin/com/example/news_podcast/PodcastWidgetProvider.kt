package com.example.news_podcast

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class PodcastWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.podcast_widget).apply {
                // Open app on widget click
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                )
                setOnClickPendingIntent(R.id.podcast_widget_container, pendingIntent)

                // Set episode info
                setTextViewText(
                    R.id.widget_episode_title,
                    widgetData.getString("episode_title", null) ?: "No Episode",
                )

                // Set artwork
                val artworkPath = widgetData.getString("artwork_path", null)
                if (artworkPath != null) {
                    try {
                        val bitmap = BitmapFactory.decodeFile(artworkPath)
                        setImageViewBitmap(R.id.widget_artwork, bitmap)
                    } catch (e: Exception) {
                        setImageViewResource(R.id.widget_artwork, android.R.drawable.ic_menu_recent_history)
                    }
                } else {
                    setImageViewResource(R.id.widget_artwork, android.R.drawable.ic_menu_recent_history)
                }

                // Play/Pause button
                val isPlaying = widgetData.getBoolean("is_playing", false)
                val buttonText = if (isPlaying) "Pause" else "Play"
                setTextViewText(R.id.widget_play_pause, buttonText)

                val playPauseIntent = HomeWidgetBackgroundIntent.getBroadcast(
                    context,
                    Uri.parse("podcastWidget://playpause"),
                )
                setOnClickPendingIntent(R.id.widget_play_pause, playPauseIntent)

                // Rewind button
                val rewindIntent = HomeWidgetBackgroundIntent.getBroadcast(
                    context,
                    Uri.parse("podcastWidget://rewind"),
                )
                setOnClickPendingIntent(R.id.widget_rewind, rewindIntent)

                // Forward button
                val forwardIntent = HomeWidgetBackgroundIntent.getBroadcast(
                    context,
                    Uri.parse("podcastWidget://forward"),
                )
                setOnClickPendingIntent(R.id.widget_forward, forwardIntent)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}

